/// Student Enrollment Services
///
/// Implements the two-stage enrollment pipeline:
/// 1) CSV metadata import (students only, no face data)
/// 2) Bulk image ZIP enrollment (face embeddings generation)
///
/// All heavy ML work is done on-device. Firebase is used only for:
/// - Storing student records and embeddings (Firestore)
/// - Temporary image storage during enrollment (Storage)

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../firebase/services/firestore_student_service.dart';
import '../../firebase/services/firebase_storage_service.dart';
import '../../ml/face_detector_service.dart';
import '../../ml/face_embedding_service.dart';

/// Result summary for CSV metadata import
class StudentCsvImportSummary {
  final int totalRows;
  final int successCount;
  final int errorCount;
  final List<String> errors;

  const StudentCsvImportSummary({
    required this.totalRows,
    required this.successCount,
    required this.errorCount,
    required this.errors,
  });
}

/// Result summary for bulk face image enrollment
class StudentImageEnrollmentSummary {
  final int totalImages;
  final int embeddingsCreated;
  final int imagesNoFace;
  final int imagesMultipleFaces;
  final int missingStudents;

  const StudentImageEnrollmentSummary({
    required this.totalImages,
    required this.embeddingsCreated,
    required this.imagesNoFace,
    required this.imagesMultipleFaces,
    required this.missingStudents,
  });
}

/// Service for importing student metadata from CSV
class StudentCsvEnrollmentService {
  final FirestoreStudentService _studentService;

  StudentCsvEnrollmentService({FirestoreStudentService? studentService})
      : _studentService = studentService ?? FirestoreStudentService();

  /// Import students from raw CSV text.
  ///
  /// Expected header:
  /// student_id,name,roll_no,academic_unit
  Future<StudentCsvImportSummary> importFromRawCsv(String csvText) async {
    final errors = <String>[];

    // Normalize line endings
    final normalized = csvText.trim();
    if (normalized.isEmpty) {
      return const StudentCsvImportSummary(
        totalRows: 0,
        successCount: 0,
        errorCount: 0,
        errors: ['CSV is empty'],
      );
    }

    final rows = const CsvToListConverter(eol: '\n').convert(normalized);
    if (rows.isEmpty) {
      return const StudentCsvImportSummary(
        totalRows: 0,
        successCount: 0,
        errorCount: 0,
        errors: ['CSV has no rows'],
      );
    }

    // Parse header
    final header = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();

    int idxStudentId = header.indexOf('student_id');
    int idxName = header.indexOf('name');
    int idxRollNo = header.indexOf('roll_no');
    int idxAcademicUnit = header.indexOf('academic_unit');

    if (idxStudentId == -1 ||
        idxName == -1 ||
        idxRollNo == -1 ||
        idxAcademicUnit == -1) {
      return StudentCsvImportSummary(
        totalRows: rows.length - 1,
        successCount: 0,
        errorCount: rows.length - 1,
        errors: [
          'CSV header must include: student_id,name,roll_no,academic_unit',
        ],
      );
    }

    int success = 0;
    int error = 0;

    // Process data rows
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      try {
        if (row.length <=
            [idxStudentId, idxName, idxRollNo, idxAcademicUnit].reduce((a, b) => a > b ? a : b)) {
          error++;
          errors.add('Row ${i + 1}: not enough columns');
          continue;
        }

        final studentId = row[idxStudentId].toString().trim();
        final name = row[idxName].toString().trim();
        final rollNo = row[idxRollNo].toString().trim();
        final academicUnit = row[idxAcademicUnit].toString().trim();

        if (studentId.isEmpty || name.isEmpty || academicUnit.isEmpty) {
          error++;
          errors.add('Row ${i + 1}: missing required fields');
          continue;
        }

        await _studentService.upsertStudentWithId(
          studentId: studentId,
          name: name,
          rollNumber: rollNo,
          classId: academicUnit,
          email: null,
        );

        success++;
      } catch (e) {
        error++;
        errors.add('Row ${i + 1}: $e');
      }
    }

    return StudentCsvImportSummary(
      totalRows: rows.length - 1,
      successCount: success,
      errorCount: error,
      errors: errors,
    );
  }
}

/// Service for bulk image ZIP enrollment
class StudentImageEnrollmentService {
  final FirestoreStudentService _studentService;
  final FirebaseStorageService _storageService;
  final FaceDetectorService _faceDetector;
  final FaceEmbeddingService _embeddingService;

  StudentImageEnrollmentService({
    FirestoreStudentService? studentService,
    FirebaseStorageService? storageService,
    FaceDetectorService? faceDetector,
    FaceEmbeddingService? embeddingService,
  })  : _studentService = studentService ?? FirestoreStudentService(),
        _storageService = storageService ?? FirebaseStorageService(),
        _faceDetector = faceDetector ?? FaceDetectorService(),
        _embeddingService = embeddingService ?? FaceEmbeddingService();

  /// Process ZIP bytes containing student images in the structure:
  /// S001/img1.jpg, S001/img2.jpg, S002/img1.jpg, ...
  Future<StudentImageEnrollmentSummary> enrollFromZipBytes(Uint8List zipBytes) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);

    // Group files by studentId (folder name)
    final Map<String, List<ArchiveFile>> filesByStudent = {};
    int totalImages = 0;

    for (final file in archive) {
      if (!file.isFile) continue;
      final path = file.name; // e.g., S001/img1.jpg
      final segments = path.split(RegExp(r'[\\/]+'));
      if (segments.length < 2) continue;
      final studentId = segments.first.trim();
      if (studentId.isEmpty) continue;
      filesByStudent.putIfAbsent(studentId, () => []).add(file);
      totalImages++;
    }

    if (totalImages == 0) {
      return const StudentImageEnrollmentSummary(
        totalImages: 0,
        embeddingsCreated: 0,
        imagesNoFace: 0,
        imagesMultipleFaces: 0,
        missingStudents: 0,
      );
    }

    // Ensure embedding model initialized
    await _embeddingService.initialize();

    int embeddingsCreated = 0;
    int imagesNoFace = 0;
    int imagesMultipleFaces = 0;
    int missingStudents = 0;

    final firestore = FirebaseFirestore.instance;

    for (final entry in filesByStudent.entries) {
      final studentId = entry.key;
      final files = entry.value;

      // Check if student exists
      final studentDoc = await firestore
          .collection(_studentService.collectionName)
          .doc(studentId)
          .get();
      if (!studentDoc.exists) {
        missingStudents++;
        continue;
      }

      // Upload all images for this student (temporary) and process
      for (final archiveFile in files) {
        try {
          final content = archiveFile.content;
          if (content is! List<int>) continue;

          final imageBytes = Uint8List.fromList(content);

          // 1) Upload temporarily to Storage (optional but keeps design compliant)
          await _storageService.uploadStudentEnrollmentImage(
            studentId: studentId,
            imageBytes: imageBytes,
          );

          // 2) Write to temp file so ML Kit can read it
          final tempDir = await getTemporaryDirectory();
          final tempFile = File(
              '${tempDir.path}/enroll_${studentId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await tempFile.writeAsBytes(imageBytes);

          // 3) Detect faces
          final faces = await _faceDetector.detectFacesFromFile(tempFile.path);

          if (faces.isEmpty) {
            imagesNoFace++;
            await tempFile.delete().catchError((_) {});
            continue;
          }
          if (faces.length > 1) {
            imagesMultipleFaces++;
            await tempFile.delete().catchError((_) {});
            continue;
          }

          final face = faces.first;

          // 4) Crop face & generate embedding
          const targetSize = 112;
          final cropped = await _faceDetector.cropFace(
            imageBytes,
            face,
            targetSize,
          );

          final embedding = await _embeddingService.generateEmbedding(cropped);

          // 5) Store embedding on student document
          await _studentService.addFaceEmbedding(
            studentId: studentId,
            embedding: embedding.vector,
          );

          embeddingsCreated++;

          // Cleanup temp file
          await tempFile.delete().catchError((_) {});
        } catch (e) {
          debugPrint('Error processing image for $studentId: $e');
          // continue with next image
        }
      }

      // Delete all temporary enrollment images for this student
      await _storageService.deleteStudentEnrollmentImages(studentId);
    }

    return StudentImageEnrollmentSummary(
      totalImages: totalImages,
      embeddingsCreated: embeddingsCreated,
      imagesNoFace: imagesNoFace,
      imagesMultipleFaces: imagesMultipleFaces,
      missingStudents: missingStudents,
    );
  }
}


