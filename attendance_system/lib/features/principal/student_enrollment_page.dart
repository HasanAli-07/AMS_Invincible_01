import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../core/services/student_enrollment_service.dart';
import '../../ml/face_repository.dart';
import '../../ml/face_recognition_service.dart';
import '../../ml/face_detector_service.dart';
import '../../ml/face_embedding_service.dart';
import '../../ml/face_matcher.dart';
import '../../design_system/tokens/radius_tokens.dart';
import '../../design_system/tokens/spacing_tokens.dart';

/// Dedicated screen for student enrollment (CSV + ZIP)
class StudentEnrollmentPage extends StatefulWidget {
  const StudentEnrollmentPage({super.key});

  @override
  State<StudentEnrollmentPage> createState() => _StudentEnrollmentPageState();
}

class _StudentEnrollmentPageState extends State<StudentEnrollmentPage> {
  final TextEditingController _csvController = TextEditingController();
  bool _isProcessingZip = false;
  bool _isImportingData = false;
  Uint8List? _excelBytes;

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
      
      setState(() {
        if (file.extension == 'xlsx') {
          _excelBytes = bytes;
          _csvController.text = '[Excel File Selected: ${file.name}]';
        } else {
          _excelBytes = null;
          _csvController.text = utf8.decode(bytes);
        }
      });
    }
  }

  Future<void> _importData() async {
    final text = _csvController.text.trim();
    if (text.isEmpty && _excelBytes == null) {
      _showSnack('Please select a file or paste CSV data.');
      return;
    }

    setState(() => _isImportingData = true);
    
    // Show loading message
    _showSnack('Importing student data...');
    
    try {
      final enrollmentService = StudentCsvEnrollmentService();
      StudentCsvImportSummary summary;

      if (_excelBytes != null && text.startsWith('[Excel')) {
        // Process Excel file
        summary = await enrollmentService.importFromExcelBytes(_excelBytes!);
      } else if (_excelBytes != null) {
        // Excel file selected but text doesn't match - try Excel anyway
        summary = await enrollmentService.importFromExcelBytes(_excelBytes!);
      } else {
        // Process CSV text
        summary = await enrollmentService.importFromRawCsv(text);
      }

      // Show results
      if (summary.errorCount > 0) {
        // Show dialog with errors
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Import Completed with ${summary.errorCount} error(s)'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Successfully imported: ${summary.successCount} students',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (summary.errorCount > 0) ...[
                      const SizedBox(height: 16),
                      const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: summary.errors.length,
                          itemBuilder: (context, index) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            title: Text(
                              summary.errors[index],
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
        
        // Also show snackbar with summary
        if (mounted) {
          _showSnack(
            'Imported: ${summary.successCount}/${summary.totalRows} students. '
            '${summary.errorCount} error(s) - see details in dialog.',
          );
        }
      } else {
        // All successful
        if (mounted) {
          _showSnack(
            'Successfully imported ${summary.successCount}/${summary.totalRows} students!',
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Import error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        _showSnack('Import error: $e');
        // Show detailed error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Error'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Error: $e'),
                  const SizedBox(height: 16),
                  const Text('Stack trace:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    stackTrace.toString(),
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isImportingData = false);
    }
  }

  Future<void> _deleteAllFaces() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Embeddings?'),
        content: const Text(
            'This will permanently remove all face data from Firestore. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessingZip = true;
    });

    try {
      // Manual instantiation since DI is minimal in this view
      final faceDetector = FaceDetectorService();
      final embeddingService = FaceEmbeddingService();
      await embeddingService.initialize();
      final faceMatcher = FaceMatcher();
      final faceRepository = FirestoreFaceRepository();

      final faceRecognition = FaceRecognitionService(
        faceDetector: faceDetector,
        embeddingService: embeddingService,
        faceMatcher: faceMatcher,
        faceRepository: faceRepository,
      );

      await faceRecognition.deleteAllFaces();

      if (mounted) {
        _showSnack('✅ All face embeddings have been deleted successfully.');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('❌ Deletion failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingZip = false;
        });
      }
    }
  }

  Future<void> _pickZip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true, // Ensure we get bytes
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();

    setState(() => _isProcessingZip = true);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Processing enrollment ZIP...')),
    );

    try {
      final enrollmentService = StudentImageEnrollmentService();
      final summary = await enrollmentService.enrollFromZipBytes(bytes);
      String message;
      if (summary.embeddingsCreated == 0) {
        if (summary.missingStudents > 0) {
          message = '❌ No embeddings created. ${summary.missingStudents} students not found in Firestore. '
              'Please upload CSV/Excel first to add students.';
        } else if (summary.imagesNoFace > 0) {
          message = '⚠️ No embeddings created. ${summary.imagesNoFace} images had no face detected. '
              'Please check image quality.';
        } else if (summary.imagesMultipleFaces > 0) {
          message = '⚠️ No embeddings created. ${summary.imagesMultipleFaces} images had multiple faces. '
              'Please use images with single face only.';
        } else {
          message = '❌ No embeddings created. Check console logs for details.';
        }
      } else {
        message = '✅ Done: ${summary.embeddingsCreated}/${summary.totalImages} images → embeddings. '
            'No face: ${summary.imagesNoFace}, Multi-face: ${summary.imagesMultipleFaces}, '
            'Missing students: ${summary.missingStudents}.';
      }
      
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Enrollment error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessingZip = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        title: const Text(
          'Student Enrollment',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroCard(
              title: 'Enroll students in two steps',
              subtitle:
                  'Step 1: Import student Data (CSV/Excel)\nStep 2: Upload ZIP of face photos',
              icon: Icons.bolt,
            ),
            const SizedBox(height: 16),
            _StepCard(
              title: 'Step 1 — Upload Student Data',
              subtitle:
                  'Required: Name, EnrollmentNo, Semester, Department, Batch',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _FormatPill(
                    title: 'Format sample:',
                    content:
                        'Name,EnrollmentNo,Semester,Department,Batch\n'
                        'John Doe,S001,4,CS,A1\n'
                        'Jane Smith,S002,4,IT,B1',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _csvController,
                    maxLines: 5,
                    readOnly: _excelBytes != null,
                    decoration: InputDecoration(
                      hintText: 'Paste CSV rows here or select a file (CSV/Excel)',
                      border: const OutlineInputBorder(),
                      hintStyle: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Select File'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isImportingData ? null : _importData,
                          icon: _isImportingData
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(_isImportingData ? 'Importing...' : 'Import Data'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _StepCard(
              title: 'Step 2 — Bulk Face Enrollment (ZIP)',
              subtitle: 'ZIP structure: student_id/img1.jpg, img2.jpg, ...',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormatPill(
                    title: 'ZIP folder example:',
                    content:
                        'root/\n'
                        '├─ s001/\n'
                        '│   ├─ img1.jpg\n'
                        '│   └─ img2.jpg\n'
                        '├─ s002/\n'
                        '    ├─ face1.jpg\n'
                        '    └─ face2.jpg',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isProcessingZip ? null : _pickZip,
                    icon: _isProcessingZip
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.folder_zip),
                    label: Text(_isProcessingZip ? 'Processing...' : 'Select ZIP for face enrollment'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Danger Zone
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: RadiusTokens.card,
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Danger Zone',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Need a fresh start? Delete all existing face data from Firestore before uploading new files.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: (_isProcessingZip || _isImportingData)
                          ? null
                          : _deleteAllFaces,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete All Face Embeddings'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: RadiusTokens.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.onPrimaryContainer.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _StepCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: RadiusTokens.card,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _FormatPill extends StatelessWidget {
  final String title;
  final String content;

  const _FormatPill({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              height: 1.3,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

