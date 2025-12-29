import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/services/student_enrollment_service.dart';
import '../../design_system/tokens/radius_tokens.dart';

/// Dedicated screen for student enrollment (CSV + ZIP)
class StudentEnrollmentPage extends StatefulWidget {
  const StudentEnrollmentPage({super.key});

  @override
  State<StudentEnrollmentPage> createState() => _StudentEnrollmentPageState();
}

class _StudentEnrollmentPageState extends State<StudentEnrollmentPage> {
  final TextEditingController _csvController = TextEditingController();
  bool _isProcessingZip = false;
  bool _isImportingCsv = false;

  @override
  void dispose() {
    _csvController.dispose();
    super.dispose();
  }

  Future<void> _pickCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
      setState(() {
        _csvController.text = utf8.decode(bytes);
      });
    }
  }

  Future<void> _importCsv() async {
    final csvText = _csvController.text.trim();
    if (csvText.isEmpty) {
      _showSnack('Please paste or select a CSV file.');
      return;
    }
    setState(() => _isImportingCsv = true);
    try {
      final enrollmentService = StudentCsvEnrollmentService();
      await enrollmentService.importFromRawCsv(csvText);
      _showSnack('CSV imported. Now upload ZIP for faces.');
    } catch (e) {
      _showSnack('CSV import error: $e');
    } finally {
      if (mounted) setState(() => _isImportingCsv = false);
    }
  }

  Future<void> _pickZip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
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
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Done: ${summary.embeddingsCreated}/${summary.totalImages} images → embeddings. '
            'No face: ${summary.imagesNoFace}, Multi-face: ${summary.imagesMultipleFaces}, '
            'Missing students: ${summary.missingStudents}.',
          ),
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
                  'Step 1: Import student CSV\nStep 2: Upload ZIP of face photos',
              icon: Icons.bolt,
            ),
            const SizedBox(height: 16),
            _StepCard(
              title: 'Step 1 — Upload Student CSV',
              subtitle:
                  'Required headers: student_id, name, roll_no, academic_unit',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormatPill(
                    title: 'CSV sample (copy/paste):',
                    content:
                        'student_id,name,roll_no,academic_unit\n'
                        's001,Jane Doe,10A001,CS-2024\n'
                        's002,John Smith,10A002,CS-2024',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _csvController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Paste CSV rows here or select a file',
                      border: const OutlineInputBorder(),
                      hintStyle: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickCsv,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Select CSV file'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isImportingCsv ? null : _importCsv,
                          icon: _isImportingCsv
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(_isImportingCsv ? 'Importing...' : 'Import CSV'),
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

