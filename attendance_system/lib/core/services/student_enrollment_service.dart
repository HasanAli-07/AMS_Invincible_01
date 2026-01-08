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

import 'package:excel/excel.dart';

import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../data/local_enrollment_db_helper.dart';

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
  /// Import students from raw CSV text.
  ///
  /// Expected header:
  /// Name, EnrollmentNo, Semester, Department, Batch
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

    // Map new fields
    // [Name, enrollmentNo, semester, department, batch(A1,B1)]
    int idxName = header.indexOf('name');
    int idxEnrollmentNo = header.indexOf('enrollmentno');
    int idxSemester = header.indexOf('semester');
    int idxDepartment = header.indexOf('department');
    int idxBatch = header.indexOf('batch');

    // Fallback for case sensitivity or slight variations if needed
    if (idxEnrollmentNo == -1) idxEnrollmentNo = header.indexOf('enrollment_no');

    if (idxName == -1 ||
        idxEnrollmentNo == -1 ||
        idxSemester == -1 ||
        idxDepartment == -1 ||
        idxBatch == -1) {
      return StudentCsvImportSummary(
        totalRows: rows.length - 1,
        successCount: 0,
        errorCount: rows.length - 1,
        errors: [
          'CSV header must include: Name, EnrollmentNo, Semester, Department, Batch',
        ],
      );
    }

    int success = 0;
    int error = 0;
    final dbHelper = LocalEnrollmentDbHelper.instance;
    await dbHelper.clearPendingStudents(); // Clear old temp data

    debugPrint('Starting CSV import. Total rows to process: ${rows.length - 1}');
    
    // Process data rows
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      try {
        // Ensure row has enough columns
        final maxIdx = [idxName, idxEnrollmentNo, idxSemester, idxDepartment, idxBatch].reduce((a, b) => a > b ? a : b);
        if (row.length <= maxIdx) {
          error++;
          errors.add('Row ${i + 1}: not enough columns');
          continue;
        }

        final name = row[idxName].toString().trim();
        final enrollmentNo = row[idxEnrollmentNo].toString().trim();
        final semester = row[idxSemester].toString().trim();
        final department = row[idxDepartment].toString().trim();
        final batch = row[idxBatch].toString().trim();

        if (name.isEmpty || enrollmentNo.isEmpty) {
          error++;
          errors.add('Row ${i + 1}: missing required Name or EnrollmentNo');
          continue;
        }

        // 1. Save to Local SQLite (Temporary)
        debugPrint('Processing row ${i + 1}: Name=$name, EnrollmentNo=$enrollmentNo, Semester=$semester, Department=$department, Batch=$batch');
        
        await dbHelper.insertPendingStudent({
          'id': enrollmentNo, // Use enrollmentNo as temporary ID
          'name': name,
          'enrollment_no': enrollmentNo,
          'semester': semester,
          'department': department,
          'batch': batch,
          'status': 'pending',
        });

        // 2. Also Upsert to Firestore (Final Enrollment) - 
        // In a real staging scenario, we might wait for user confirmation.
        // For now, we do both to satisfy "store upload" requirement while keeping existing flow working.
        
        // We map 'enrollmentNo' to 'studentId' and 'rollNumber' for backward compatibility
        debugPrint('Uploading student to Firestore: $enrollmentNo - $name');
        try {
          await _studentService.upsertStudentWithId(
            studentId: enrollmentNo, 
            name: name,
            rollNumber: enrollmentNo, // Using enrollmentNo as rollNumber
            classId: '$department-$semester-$batch', // Generate academic unit/classId
            email: null,
            // TODO: Update upsertStudentWithId to accept new fields if Firestore needs them explicitly
          );
          debugPrint('Successfully uploaded student: $enrollmentNo');
        } catch (firestoreError) {
          debugPrint('Firestore upload error for $enrollmentNo: $firestoreError');
          error++;
          errors.add('Row ${i + 1}: Firestore upload failed - $firestoreError');
          continue; // Skip this student
        }

        success++;
      } catch (e) {
        error++;
        errors.add('Row ${i + 1}: $e');
      }
    }

    debugPrint('CSV import completed: $success successes, $error errors out of ${rows.length - 1} total rows');
    
    return StudentCsvImportSummary(
      totalRows: rows.length - 1,
      successCount: success,
      errorCount: error,
      errors: errors,
    );
  }
  /// Import students from Excel file bytes.
  ///
  /// Expected header:
  /// Name, EnrollmentNo, Semester, Department, Batch
  Future<StudentCsvImportSummary> importFromExcelBytes(Uint8List bytes) async {
    final errors = <String>[];
    
    var excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      return StudentCsvImportSummary(
        totalRows: 0,
        successCount: 0,
        errorCount: 1,
        errors: ['Excel file has no sheets'],
      );
    }

    // Assume data is in the first sheet
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName];
    if (sheet == null || sheet.rows.isEmpty) {
      return StudentCsvImportSummary(
        totalRows: 0,
        successCount: 0,
        errorCount: 1,
        errors: ['Excel sheet is empty'],
      );
    }

    // Convert rows to list of strings
    final rows = sheet.rows.map((row) {
      return row.map((cell) => StudentCsvEnrollmentService.getCellValue(cell?.value)).toList();
    }).toList();
    
    if (rows.isEmpty) {
      return StudentCsvImportSummary(
        totalRows: 0,
        successCount: 0,
        errorCount: 1,
        errors: ['Sheet has no rows'],
      );
    }
    
    if (rows.length < 2) {
      return StudentCsvImportSummary(
        totalRows: 0,
        successCount: 0,
        errorCount: 1,
        errors: ['Excel file contains only a header row (no student data found).'],
      );
    }
    
    // Reuse parsing logic
    // Parse header - be more flexible with matching
    final header = rows.first.map((e) => e.toString().trim()).toList();
    final headerLower = header.map((e) => e.toLowerCase()).toList();

    debugPrint('Excel header row: $header');
    debugPrint('Total rows in sheet: ${rows.length}');

    // Try multiple variations of column names
    int idxName = headerLower.indexOf('name');
    if (idxName == -1) idxName = headerLower.indexWhere((h) => h.contains('name'));
    
    int idxEnrollmentNo = headerLower.indexOf('enrollmentno');
    if (idxEnrollmentNo == -1) idxEnrollmentNo = headerLower.indexOf('enrollment_no');
    if (idxEnrollmentNo == -1) idxEnrollmentNo = headerLower.indexWhere((h) => h.contains('enrollment'));
    if (idxEnrollmentNo == -1) idxEnrollmentNo = headerLower.indexWhere((h) => h.contains('enroll'));
    
    int idxSemester = headerLower.indexOf('semester');
    if (idxSemester == -1) idxSemester = headerLower.indexWhere((h) => h.contains('semester'));
    
    int idxDepartment = headerLower.indexOf('department');
    if (idxDepartment == -1) idxDepartment = headerLower.indexWhere((h) => h.contains('department'));
    if (idxDepartment == -1) idxDepartment = headerLower.indexWhere((h) => h.contains('dept'));
    
    int idxBatch = headerLower.indexOf('batch');
    if (idxBatch == -1) idxBatch = headerLower.indexWhere((h) => h.contains('batch'));

    debugPrint('Column indices - Name: $idxName, EnrollmentNo: $idxEnrollmentNo, Semester: $idxSemester, Department: $idxDepartment, Batch: $idxBatch');

    if (idxName == -1 ||
        idxEnrollmentNo == -1 ||
        idxSemester == -1 ||
        idxDepartment == -1 ||
        idxBatch == -1) {
      final missing = <String>[];
      if (idxName == -1) missing.add('Name');
      if (idxEnrollmentNo == -1) missing.add('EnrollmentNo');
      if (idxSemester == -1) missing.add('Semester');
      if (idxDepartment == -1) missing.add('Department');
      if (idxBatch == -1) missing.add('Batch');
      
      return StudentCsvImportSummary(
        totalRows: rows.length - 1,
        successCount: 0,
        errorCount: rows.length - 1,
        errors: [
          'Excel header missing required columns: ${missing.join(", ")}. Found columns: ${header.join(", ")}',
        ],
      );
    }

    int success = 0;
    int error = 0;
    final dbHelper = LocalEnrollmentDbHelper.instance;
    await dbHelper.clearPendingStudents();

    debugPrint('Processing ${rows.length - 1} data rows...');
    
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      try {
        // Skip completely empty rows
        if (row.isEmpty || row.every((c) => c.toString().trim().isEmpty)) {
          debugPrint('Skipping empty row ${i + 1}');
          continue;
        }
        
        final maxIdx = [idxName, idxEnrollmentNo, idxSemester, idxDepartment, idxBatch].reduce((a, b) => a > b ? a : b);
        if (row.length <= maxIdx) {
          error++;
          errors.add('Row ${i + 1}: not enough columns (has ${row.length}, needs at least ${maxIdx + 1}). Row: $row');
          continue;
        }

        final name = row[idxName].toString().trim();
        final enrollmentNo = row[idxEnrollmentNo].toString().trim();
        final semester = row[idxSemester].toString().trim();
        final department = row[idxDepartment].toString().trim();
        final batch = row[idxBatch].toString().trim();

        debugPrint('Row ${i + 1}: Name=$name, EnrollmentNo=$enrollmentNo, Semester=$semester, Department=$department, Batch=$batch');

        if (name.isEmpty || enrollmentNo.isEmpty) {
          error++;
          errors.add('Row ${i + 1}: missing required Name or EnrollmentNo');
          continue;
        }

        await dbHelper.insertPendingStudent({
          'id': enrollmentNo,
          'name': name,
          'enrollment_no': enrollmentNo,
          'semester': semester,
          'department': department,
          'batch': batch,
          'status': 'pending',
        });

        debugPrint('Uploading student to Firestore: $enrollmentNo - $name');
        try {
          await _studentService.upsertStudentWithId(
            studentId: enrollmentNo, 
            name: name,
            rollNumber: enrollmentNo, 
            classId: '$department-$semester-$batch',
            email: null,
          );
          debugPrint('Successfully uploaded student: $enrollmentNo');
        } catch (firestoreError) {
          debugPrint('Firestore upload error for $enrollmentNo: $firestoreError');
          error++;
          errors.add('Row ${i + 1}: Firestore upload failed - $firestoreError');
          continue; // Skip this student
        }

        success++;
      } catch (e) {
        error++;
        errors.add('Row ${i + 1}: $e');
      }
    }

    debugPrint('Import complete: $success successes, $error errors out of ${rows.length - 1} total rows');
    
    // Calculate actual rows processed (non-empty)
    final totalDataRows = rows.length - 1; // Exclude header
    
    if (success == 0 && error == 0 && totalDataRows > 0) {
      return StudentCsvImportSummary(
        totalRows: totalDataRows,
        successCount: 0,
        errorCount: 1,
        errors: ['No valid student data found. All ${totalDataRows} row(s) were empty or skipped.'],
      );
    }
    
    if (totalDataRows == 0) {
      return StudentCsvImportSummary(
        totalRows: 0,
        successCount: 0,
        errorCount: 1,
        errors: ['Excel file contains only header row. No student data found.'],
      );
    }

    return StudentCsvImportSummary(
      totalRows: totalDataRows,
      successCount: success,
      errorCount: error,
      errors: errors,
    );
  }

  static String getCellValue(CellValue? value) {
    if (value == null) return '';
    if (value is TextCellValue) {
      return value.value.toString().trim();
    } else if (value is IntCellValue) {
      return value.value.toString();
    } else if (value is DoubleCellValue) {
      return value.value.toString();
    } else if (value is DateCellValue) {
      return value.year.toString();
    }
    return value.toString().trim();
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
    debugPrint('=' * 60);
    debugPrint('Starting ZIP enrollment process...');
    debugPrint('=' * 60);
    
    final archive = ZipDecoder().decodeBytes(zipBytes);

    // Group files by studentId (folder name)
    final Map<String, List<ArchiveFile>> filesByStudent = {};
    int totalImages = 0;

    for (final file in archive) {
      if (!file.isFile) continue;
      final path = file.name; // e.g., S001/img1.jpg or Students - Copy/S001/img1.jpg
      final segments = path.split(RegExp(r'[\\/]+')).where((s) => s.trim().isNotEmpty).toList();
      if (segments.length < 2) continue;
      
      // Find studentId: it's the folder name that contains the image file
      // For "Students - Copy/240140107001/image.jpg", studentId = "240140107001"
      // For "S001/img1.jpg", studentId = "S001"
      // The studentId is always the second-to-last segment (folder containing the image)
      final studentId = segments[segments.length - 2].trim();
      if (studentId.isEmpty) continue;
      
      filesByStudent.putIfAbsent(studentId, () => []).add(file);
      totalImages++;
    }
    
    debugPrint('ZIP parsed: Found ${filesByStudent.length} students with $totalImages total images');
    debugPrint('Student IDs found in ZIP: ${filesByStudent.keys.toList()}');
    
    // Check Firestore for matching students BEFORE processing
    debugPrint('Checking Firestore for matching students...');
    final firestore = FirebaseFirestore.instance;
    final allStudentsSnapshot = await firestore
        .collection(_studentService.collectionName)
        .limit(50)
        .get();
    
    debugPrint('Total students in Firestore: ${allStudentsSnapshot.docs.length}');
    debugPrint('Sample Firestore students:');
    for (var i = 0; i < allStudentsSnapshot.docs.length && i < 10; i++) {
      final doc = allStudentsSnapshot.docs[i];
      final data = doc.data();
      debugPrint('  ${i + 1}. Doc ID: ${doc.id}, rollNumber: ${data['rollNumber']}, enrollmentNo: ${data['enrollmentNo']}, name: ${data['name']}');
    }
    
    // Check which ZIP students will match
    debugPrint('Matching ZIP students with Firestore:');
    for (final zipStudentId in filesByStudent.keys) {
      final zipIdWithSuffix = '$zipStudentId.0';
      final docById = await firestore.collection(_studentService.collectionName).doc(zipStudentId).get();
      final docByIdSuffix = await firestore.collection(_studentService.collectionName).doc(zipIdWithSuffix).get();
      final queryByRoll = await firestore.collection(_studentService.collectionName).where('rollNumber', isEqualTo: zipStudentId).limit(1).get();
      final queryByRollSuffix = await firestore.collection(_studentService.collectionName).where('rollNumber', isEqualTo: zipIdWithSuffix).limit(1).get();
      
      bool found = docById.exists || docByIdSuffix.exists || queryByRoll.docs.isNotEmpty || queryByRollSuffix.docs.isNotEmpty;
      debugPrint('  ZIP ID: $zipStudentId -> Match: ${found ? "✅ YES" : "❌ NO"}');
      if (found) {
        String matchType = '';
        if (docById.exists) matchType = 'by doc ID';
        else if (docByIdSuffix.exists) matchType = 'by doc ID with .0 suffix';
        else if (queryByRoll.docs.isNotEmpty) matchType = 'by rollNumber';
        else if (queryByRollSuffix.docs.isNotEmpty) matchType = 'by rollNumber with .0 suffix';
        debugPrint('    Match type: $matchType');
      }
    }
    debugPrint('=' * 60);

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

    for (final entry in filesByStudent.entries) {
      final studentId = entry.key;
      final files = entry.value;

      debugPrint('Processing student: $studentId with ${files.length} images');

      // Normalize studentId: remove .0 suffix if present, we'll add it back if needed
      String normalizedStudentId = studentId;
      bool hasSuffix = studentId.endsWith('.0');
      if (hasSuffix) {
        normalizedStudentId = studentId.substring(0, studentId.length - 2);
        debugPrint('ZIP folder has .0 suffix, normalized to: $normalizedStudentId');
      }
      
      // Check if student exists - try multiple approaches
      DocumentSnapshot? studentDoc = await firestore
          .collection(_studentService.collectionName)
          .doc(studentId) // Try exact match first (in case ZIP folder = doc ID)
          .get();
      
      String? actualStudentDocId = studentId;
      
      // If not found by exact document ID, try normalized version
      if (!studentDoc.exists && hasSuffix) {
        debugPrint('Trying normalized document ID: $normalizedStudentId');
        studentDoc = await firestore
            .collection(_studentService.collectionName)
            .doc(normalizedStudentId)
            .get();
        if (studentDoc.exists) {
          actualStudentDocId = normalizedStudentId;
          debugPrint('✅ Found student by normalized document ID: $normalizedStudentId');
        }
      }
      
      // If still not found, try with .0 suffix (for cases where ZIP doesn't have suffix)
      if (!studentDoc.exists && !hasSuffix) {
        final studentIdWithSuffix = '$studentId.0';
        debugPrint('Trying document ID with .0 suffix: $studentIdWithSuffix');
        studentDoc = await firestore
            .collection(_studentService.collectionName)
            .doc(studentIdWithSuffix)
            .get();
        if (studentDoc.exists) {
          actualStudentDocId = studentIdWithSuffix;
          debugPrint('✅ Found student by document ID with .0 suffix: $studentIdWithSuffix');
        }
      }
      
      // If not found by document ID, try searching by rollNumber field
      if (!studentDoc.exists) {
        debugPrint('Student not found by document ID, searching by rollNumber field...');
        
        // Try exact rollNumber match
        var querySnapshot = await firestore
            .collection(_studentService.collectionName)
            .where('rollNumber', isEqualTo: studentId)
            .limit(1)
            .get();
        
        // Try normalized rollNumber
        if (querySnapshot.docs.isEmpty && hasSuffix) {
          querySnapshot = await firestore
              .collection(_studentService.collectionName)
              .where('rollNumber', isEqualTo: normalizedStudentId)
              .limit(1)
              .get();
        }
        
        // Try with .0 suffix
        if (querySnapshot.docs.isEmpty && !hasSuffix) {
          final studentIdWithSuffix = '$studentId.0';
          querySnapshot = await firestore
              .collection(_studentService.collectionName)
              .where('rollNumber', isEqualTo: studentIdWithSuffix)
              .limit(1)
              .get();
        }
        
        if (querySnapshot.docs.isNotEmpty) {
          studentDoc = querySnapshot.docs.first;
          actualStudentDocId = studentDoc!.id;
          debugPrint('✅ Found student by rollNumber field, document ID: $actualStudentDocId');
        }
        
        // If not found, try enrollmentNo field
        if (querySnapshot.docs.isEmpty && (studentDoc == null || !studentDoc!.exists)) {
          querySnapshot = await firestore
              .collection(_studentService.collectionName)
              .where('enrollmentNo', isEqualTo: studentId)
              .limit(1)
              .get();
        }
        
        // If still not found, try to match with any field containing the enrollment number
        if (querySnapshot.docs.isEmpty) {
          debugPrint('Trying to find student by fetching all students and matching...');
          final allStudentsSnapshot = await firestore
              .collection(_studentService.collectionName)
              .limit(200) // Increased limit
              .get();
          
          debugPrint('Total students in Firestore: ${allStudentsSnapshot.docs.length}');
          debugPrint('Looking for enrollment number: $studentId');
          
          // Log first few students for debugging
          if (allStudentsSnapshot.docs.isNotEmpty) {
            debugPrint('Sample students in Firestore:');
            for (var i = 0; i < allStudentsSnapshot.docs.length && i < 5; i++) {
              final doc = allStudentsSnapshot.docs[i];
              final data = doc.data();
              debugPrint('  Doc ${i + 1}: ID=${doc.id}, rollNumber=${data['rollNumber']}, enrollmentNo=${data['enrollmentNo']}, name=${data['name']}');
            }
          }
          
          for (final doc in allStudentsSnapshot.docs) {
            final data = doc.data();
            final rollNo = data['rollNumber']?.toString().trim() ?? '';
            final enrollNo = data['enrollmentNo']?.toString().trim() ?? '';
            final docId = doc.id.trim();
            final searchId = studentId.trim();
            final searchIdWithSuffix = '$searchId.0';
            
            debugPrint('Comparing: searchId=$searchId vs rollNo=$rollNo, enrollNo=$enrollNo, docId=$docId');
            
            // Match with or without .0 suffix
            if (rollNo == searchId || rollNo == searchIdWithSuffix ||
                enrollNo == searchId || enrollNo == searchIdWithSuffix ||
                docId == searchId || docId == searchIdWithSuffix) {
              studentDoc = doc;
              actualStudentDocId = doc.id;
              debugPrint('✅ Found student by manual search: rollNumber=$rollNo, enrollmentNo=$enrollNo, docId=$docId');
              break;
            }
          }
        } else {
          // Found by query
          studentDoc = querySnapshot.docs.first;
          actualStudentDocId = studentDoc!.id;
          final data = studentDoc!.data() as Map<String, dynamic>;
          debugPrint('✅ Found student with rollNumber/enrollmentNo=$studentId, actual document ID: $actualStudentDocId');
          debugPrint('   Student data: name=${data['name']}, rollNumber=${data['rollNumber']}, enrollmentNo=${data['enrollmentNo']}');
        }
        
        // Check if student was found
        if (studentDoc == null || !studentDoc!.exists) {
          debugPrint('❌ Student $studentId not found in Firestore (checked document ID, rollNumber, enrollmentNo fields)');
          debugPrint('   Tip: Make sure enrollment number matches Firestore document ID or rollNumber/enrollmentNo field');
          missingStudents++;
          continue;
        }
      } else {
        debugPrint('✅ Student $studentId found in Firestore by document ID');
      }
      
      // Use actual document ID for further operations
      final finalStudentId = actualStudentDocId!;

      // Upload all images for this student (temporary) and process
      debugPrint('Starting to process ${files.length} images for student $finalStudentId...');
      for (final archiveFile in files) {
        try {
          debugPrint('Processing image: ${archiveFile.name}');
          final content = archiveFile.content;
          if (content is! List<int>) {
            debugPrint('⚠️ Image content is not List<int>, skipping');
            continue;
          }

          final imageBytes = Uint8List.fromList(content);
          debugPrint('Image loaded: ${imageBytes.length} bytes');

          // 1) Upload temporarily to Storage (optional - skip if fails)
          try {
            await _storageService.uploadStudentEnrollmentImage(
              studentId: finalStudentId,
              imageBytes: imageBytes,
            );
            debugPrint('Image uploaded to Storage successfully');
          } catch (storageError) {
            debugPrint('⚠️ Storage upload failed (continuing anyway): $storageError');
            // Continue without Storage - embeddings will still be stored in Firestore
          }

          // 2) Write to temp file so ML Kit can read it
          final tempDir = await getTemporaryDirectory();
          final tempFile = File(
              '${tempDir.path}/enroll_${finalStudentId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await tempFile.writeAsBytes(imageBytes);

          // 3) Detect faces
          debugPrint('Detecting faces in image ${archiveFile.name} for student $finalStudentId...');
          final faces = await _faceDetector.detectFacesFromFile(tempFile.path);
          debugPrint('Face detection result: ${faces.length} face(s) found');

          if (faces.isEmpty) {
            debugPrint('⚠️ No face detected in image ${archiveFile.name}');
            imagesNoFace++;
            await tempFile.delete().catchError((_) {});
            continue;
          }
          if (faces.length > 1) {
            debugPrint('⚠️ Multiple faces (${faces.length}) detected in image ${archiveFile.name}');
            imagesMultipleFaces++;
            await tempFile.delete().catchError((_) {});
            continue;
          }

          final face = faces.first;
          debugPrint('✅ Single face detected successfully');

          // 4) Crop face & generate embedding
          const targetSize = 112;
          debugPrint('Cropping face from image ${archiveFile.name} for student $finalStudentId...');
          final cropped = await _faceDetector.cropFace(
            imageBytes,
            face,
            targetSize,
          );
          debugPrint('Face cropped successfully, size: ${cropped.length} bytes');

          debugPrint('Generating embedding for student $finalStudentId...');
          final embedding = await _embeddingService.generateEmbedding(cropped);
          debugPrint('Embedding generated successfully, size: ${embedding.vector.length} dimensions');
          debugPrint('Embedding sample (first 5 values): ${embedding.vector.take(5).toList()}');

          // 5) Store embedding on student document (use actual document ID)
          debugPrint('Storing embedding to Firestore for student $finalStudentId...');
          try {
            await _studentService.addFaceEmbedding(
              studentId: finalStudentId,
              embedding: embedding.vector,
            );
            debugPrint('✅ Embedding stored successfully in Firestore');
          } catch (e) {
            debugPrint('❌ Error storing embedding: $e');
            throw e;
          }

          embeddingsCreated++;
          debugPrint('✅ Created embedding #$embeddingsCreated for student (ZIP folder: $studentId, Firestore doc: $finalStudentId) from image ${archiveFile.name}');

          // Cleanup temp file
          await tempFile.delete().catchError((_) {});
        } catch (e, stackTrace) {
          debugPrint('❌ Error processing image ${archiveFile.name} for student $studentId: $e');
          debugPrint('Stack trace: $stackTrace');
          // continue with next image
        }
      }

      // Delete all temporary enrollment images for this student (optional)
      try {
        await _storageService.deleteStudentEnrollmentImages(finalStudentId);
      } catch (e) {
        debugPrint('⚠️ Error deleting Storage images (non-critical): $e');
        // Continue - this is cleanup, not critical
      }
    }

    debugPrint('=' * 50);
    debugPrint('ZIP Enrollment Summary:');
    debugPrint('  Total images processed: $totalImages');
    debugPrint('  Embeddings created: $embeddingsCreated');
    debugPrint('  Images with no face: $imagesNoFace');
    debugPrint('  Images with multiple faces: $imagesMultipleFaces');
    debugPrint('  Missing students: $missingStudents');
    debugPrint('=' * 50);
    
    return StudentImageEnrollmentSummary(
      totalImages: totalImages,
      embeddingsCreated: embeddingsCreated,
      imagesNoFace: imagesNoFace,
      imagesMultipleFaces: imagesMultipleFaces,
      missingStudents: missingStudents,
    );
  }
}


