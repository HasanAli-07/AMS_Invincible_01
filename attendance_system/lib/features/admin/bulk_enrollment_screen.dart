/// Bulk Enrollment Screen
/// 
/// Allows admin/principal to upload:
/// 1. CSV file with student details
/// 2. ZIP file with student images
/// 
/// Triggers BulkEnrollmentService processing.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import '../../core/services/student_enrollment_service.dart';
import '../../ml/bulk_enrollment_service.dart';
import '../../ml/face_recognition_service.dart';
import '../../ml/face_detector_service.dart';
import '../../ml/face_embedding_service.dart';
import '../../ml/face_matcher.dart';
import '../../ml/face_repository.dart';
import '../../design_system/components/ds_app_bar.dart';
import '../../design_system/components/ds_button.dart';
import '../../design_system/components/ds_card.dart';
import '../../design_system/components/ds_text.dart';
import '../../design_system/tokens/typography_tokens.dart';



class BulkEnrollmentScreen extends StatefulWidget {
  const BulkEnrollmentScreen({super.key});

  @override
  State<BulkEnrollmentScreen> createState() => _BulkEnrollmentScreenState();
}

class _BulkEnrollmentScreenState extends State<BulkEnrollmentScreen> {
  // Services
  late final BulkEnrollmentService _bulkEnrollmentService;
  
  // State
  bool _isProcessing = false;
  String? _csvFileName;
  String? _csvContent;
  String? _zipFileName;
  Uint8List? _zipBytes;
  
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    // In a real app, use dependency injection (Provider/GetIt)
    final faceDetector = FaceDetectorService();
    final embeddingService = FaceEmbeddingService()..initialize();
    final faceMatcher = FaceMatcher();
    final faceRepository = FirestoreFaceRepository(); // Use Firestore

    final faceRecognitionService = FaceRecognitionService(
      faceDetector: faceDetector,
      embeddingService: embeddingService,
      faceMatcher: faceMatcher,
      faceRepository: faceRepository,
    );

    _bulkEnrollmentService = BulkEnrollmentService(
      faceRecognitionService: faceRecognitionService,
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt', 'xlsx'],
      withData: true,
    );

    if (result != null) {
      final file = result.files.single;
      final bytes = file.bytes;
      
      if (bytes != null) {
        setState(() {
          _csvFileName = file.name;
          if (file.extension == 'xlsx') {
             try {
               var excel = Excel.decodeBytes(bytes);
               if (excel.tables.isNotEmpty) {
                 final sheet = excel.tables[excel.tables.keys.first];
                 if (sheet != null) {
                   // Convert to CSV string: "col1,col2\nval1,val2"
                   final buffer = StringBuffer();
                   for (final row in sheet.rows) {
                     buffer.writeln(row.map((e) => StudentCsvEnrollmentService.getCellValue(e?.value)).join(','));
                   }
                   _csvContent = buffer.toString();
                   _logs.add('Excel Parsed: $_csvFileName (${sheet.rows.length} rows)');
                 }
               }
             } catch (e) {
               _logs.add('Error parsing Excel: $e');
             }
          } else {
            _csvContent = String.fromCharCodes(bytes);
            _logs.add('CSV Selected: $_csvFileName');
          }
        });
      }
    }
  }

  Future<void> _pickZip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _zipFileName = result.files.single.name;
        _zipBytes = result.files.single.bytes;
        _logs.add('ZIP Selected: $_zipFileName');
      });
    }
  }

  Future<void> _startEnrollment() async {
    if (_csvContent == null || _zipBytes == null) return;

    setState(() {
      _isProcessing = true;
      _logs.add('Starting bulk enrollment process...');
    });

    try {
      final result = await _bulkEnrollmentService.processEnrollment(
        zipBytes: _zipBytes!,
        csvContent: _csvContent!,
      );

      setState(() {
        _logs.add('Total Students in CSV: ${result.totalStudentsFound}');
        _logs.add('Total Images in ZIP: ${result.totalImagesFound}');
        _logs.add('Successfully Enrolled: ${result.successfulEnrollments}');
        
        if (result.hasFailures) {
          _logs.add('Failures:');
          for (final failure in result.failures) {
            _logs.add(' - $failure');
          }
        }
      });
    } catch (e) {
      setState(() {
        _logs.add('CRITICAL ERROR: $e');
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Simple way to get colors if extension isn't working perfectly in this context, 
    // but ideally we rely on the same design system as other screens.
    // Assuming context.colors works via extension import in other files.
    // Only imports are standard relative. We can just use Theme.of for compatibility.
    return Scaffold(
      appBar: DSAppBar(
        name: 'Bulk Enrollment',
        department: 'Admin Panel',
        onLogoutTap: () => Navigator.pop(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            DSCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DSText('Two-Step Enrollment', role: TypographyRole.headline),
                  const SizedBox(height: 16),
                  const Text('1. Upload CSV with Student ID and Name (header: id,name)'),
                  const Text('2. Upload ZIP with face images (filenames: studentId_1.jpg)'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // File Pickers
            Row(
              children: [
                Expanded(
                  child: DSButton(
                    label: _csvFileName ?? 'Select Data File',
                    icon: Icons.description,
                    variant: _csvFileName != null 
                        ? DSButtonVariant.secondary 
                        : DSButtonVariant.primary,
                    onPressed: _isProcessing ? null : _pickFile,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DSButton(
                    label: _zipFileName ?? 'Select ZIP File',
                    icon: Icons.folder_zip,
                    variant: _zipFileName != null 
                        ? DSButtonVariant.secondary 
                        : DSButtonVariant.primary,
                    onPressed: _isProcessing ? null : _pickZip,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Process Button
            DSButton(
              label: _isProcessing ? 'Processing...' : 'Start Enrollment',
              icon: Icons.play_arrow,
              onPressed: (_isProcessing || _csvContent == null || _zipBytes == null)
                  ? null
                  : _startEnrollment,
            ),
            const SizedBox(height: 24),

            // Logs
            DSCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DSText('Process Log', role: TypographyRole.headline),
                  const SizedBox(height: 16),
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            _logs[index],
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                        );
                      },
                    ),
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
