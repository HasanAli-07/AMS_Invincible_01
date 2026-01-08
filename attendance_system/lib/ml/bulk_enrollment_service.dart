/// Bulk Enrollment Service
/// 
/// Handles the "Two-Step" enrollment process:
/// 1. Parse Student Metadata (CSV)
/// 2. Process Bulk Images (ZIP)
/// 3. Generate Embeddings & Store in Firestore

import 'dart:io';
import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'face_recognition_service.dart';
import 'face_models.dart';

class BulkEnrollmentService {
  final FaceRecognitionService _faceRecognitionService;

  BulkEnrollmentService({
    required FaceRecognitionService faceRecognitionService,
  }) : _faceRecognitionService = faceRecognitionService;

  /// Process Bulk Enrollment
  /// 
  /// Returns a report of success/failures
  Future<BulkEnrollmentResult> processEnrollment({
    required Uint8List zipBytes,
    required String csvContent,
  }) async {
    final result = BulkEnrollmentResult();
    
    // Step 1: Parse CSV to get student map (ID -> Name)
    final studentMap = _parseStudentCsv(csvContent);
    result.totalStudentsFound = studentMap.length;
    
    if (studentMap.isEmpty) {
      throw Exception('No valid student records found in CSV');
    }

    // Step 2: Extract ZIP
    final archive = ZipDecoder().decodeBytes(zipBytes);
    result.totalImagesFound = archive.length;

    // Step 3: Process each image
    for (final file in archive) {
      if (!file.isFile) continue;
      
      // Filename format expectation: "studentId/image1.jpg" or "studentId_1.jpg"
      // We'll assume folder structure: "studentId/any_image_name.jpg" 
      // OR flat structure with naming convention: "studentId_suffix.jpg"
      
      final filename = file.name;
      final studentId = _extractStudentIdFromFilename(filename);
      
      if (studentId == null || !studentMap.containsKey(studentId)) {
        result.failures.add('Skipped $filename: Unknown or extractable Student ID');
        continue;
      }

      final studentName = studentMap[studentId]!;

      try {
        final content = file.content as Uint8List;
        
        await _faceRecognitionService.registerFace(
          userId: studentId,
          userName: studentName,
          imageBytes: content,
          imagePath: 'bulk_import/$filename', // Virtual path reference
        );
        
        result.successfulEnrollments++;
      } catch (e) {
        result.failures.add('Failed $filename: $e');
      }
    }

    return result;
  }

  /// Parse CSV content
  /// Format: student_id, student_name, class, etc.
  Map<String, String> _parseStudentCsv(String csvContent) {
    final rows = const CsvToListConverter().convert(csvContent);
    final map = <String, String>{};

    // Assume header row exists, skip it
    if (rows.length < 2) return map;

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 2) continue;

      final id = row[0].toString().trim();
      final name = row[1].toString().trim();
      
      if (id.isNotEmpty && name.isNotEmpty) {
        map[id] = name;
      }
    }
    return map;
  }

  /// Extract Student ID from filename
  /// Supports:
  /// - Folder: "student_123/image.jpg" -> "student_123"
  /// - Flat: "student_123_1.jpg" -> "student_123"
  String? _extractStudentIdFromFilename(String path) {
    // Check for folder separator
    if (path.contains('/')) {
      final parts = path.split('/');
      // Return parent folder name if it's not root
      if (parts.length > 1) return parts[parts.length - 2]; 
    }
    
    // Check for flat file underscore convention
    final basename = path.split('/').last;
    if (basename.contains('_')) {
      return basename.split('_').first;
    }
    
    // Check for flat file dot convention (e.g. 12345.jpg)
    return basename.split('.').first;
  }
}

class BulkEnrollmentResult {
  int totalStudentsFound = 0;
  int totalImagesFound = 0;
  int successfulEnrollments = 0;
  List<String> failures = [];
  
  bool get hasFailures => failures.isNotEmpty;
}
