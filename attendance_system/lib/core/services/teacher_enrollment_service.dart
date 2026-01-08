/// Teacher Enrollment Service
///
/// Handles teacher/faculty data import from CSV/Excel or manual entry
/// Format: Name, Department, Subjects (comma-separated subject codes like "123456")
/// Password: "123456" saved for all teachers

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';

import '../../firebase/services/firestore_teacher_service.dart';
import '../../firebase/services/firestore_subject_service.dart';

/// Result summary for teacher import
class TeacherImportSummary {
  final int totalRows;
  final int successCount;
  final int errorCount;
  final List<String> errors;

  const TeacherImportSummary({
    required this.totalRows,
    required this.successCount,
    required this.errorCount,
    required this.errors,
  });
}

/// Service for importing teachers from CSV/Excel or manual entry
class TeacherEnrollmentService {
  final FirestoreTeacherService _teacherService;
  final FirestoreSubjectService _subjectService;

  TeacherEnrollmentService({
    FirestoreTeacherService? teacherService,
    FirestoreSubjectService? subjectService,
  })  : _teacherService = teacherService ?? FirestoreTeacherService(),
        _subjectService = subjectService ?? FirestoreSubjectService();

  /// Import teachers from raw CSV text
  ///
  /// Expected header: Name, Department, Subjects
  /// Subjects: Comma-separated subject codes (e.g., "CS201,CS202" or "123456")
  Future<TeacherImportSummary> importFromRawCsv(String csvText) async {
    final errors = <String>[];

    final normalized = csvText.trim();
    if (normalized.isEmpty) {
      return const TeacherImportSummary(
        totalRows: 0,
        successCount: 0,
        errorCount: 0,
        errors: ['CSV is empty'],
      );
    }

    final rows = const CsvToListConverter(eol: '\n').convert(normalized);
    if (rows.isEmpty) {
      return const TeacherImportSummary(
        totalRows: 0,
        successCount: 0,
        errorCount: 0,
        errors: ['CSV has no rows'],
      );
    }

    if (rows.length < 2) {
      return const TeacherImportSummary(
        totalRows: 0,
        successCount: 0,
        errorCount: 0,
        errors: ['CSV must have header row and at least one data row'],
      );
    }

    final header = rows[0].map((e) => e.toString().trim()).toList();
    debugPrint('CSV Header: $header');

    // Find column indices (case-insensitive)
    final nameIndex = _findColumnIndex(header, ['name']);
    final departmentIndex = _findColumnIndex(header, ['department', 'dept']);
    final subjectsIndex = _findColumnIndex(header, ['subjects', 'subject', 'subjectcodes']);

    if (nameIndex == -1 || departmentIndex == -1 || subjectsIndex == -1) {
      return TeacherImportSummary(
        totalRows: rows.length - 1,
        successCount: 0,
        errorCount: rows.length - 1,
        errors: [
          'Missing required columns. Found: $header. Required: Name, Department, Subjects'
        ],
      );
    }

    int successCount = 0;
    int rowNumber = 1;

    // Get all subjects once for code-to-ID mapping
    final allSubjects = await _subjectService.getAllSubjects();
    debugPrint('Loaded ${allSubjects.length} subjects for code mapping');

    for (var i = 1; i < rows.length; i++) {
      rowNumber++;
      final row = rows[i];

      if (row.length < header.length) {
        errors.add('Row $rowNumber: Insufficient columns (expected ${header.length}, got ${row.length})');
        continue;
      }

      try {
        final name = row[nameIndex]?.toString().trim() ?? '';
        final department = row[departmentIndex]?.toString().trim() ?? '';
        final subjectsStr = row[subjectsIndex]?.toString().trim() ?? '';

        // Validation
        if (name.isEmpty) {
          errors.add('Row $rowNumber: Name is required');
          continue;
        }
        if (department.isEmpty) {
          errors.add('Row $rowNumber: Department is required');
          continue;
        }

        // Parse subject codes and convert to IDs
        final subjectIds = await _parseSubjectCodes(subjectsStr, allSubjects);
        if (subjectsStr.isNotEmpty && subjectIds.isEmpty) {
          // Warning: Subjects not found, but still create teacher with empty subjectIds
          errors.add('Row $rowNumber: Warning - Subject codes "$subjectsStr" not found in database. Teacher created without subjects.');
          debugPrint('Warning: Row $rowNumber - Subject codes "$subjectsStr" not found. Creating teacher without subjects.');
        }

        // Generate email from name (simple: name.replaceAll(' ', '').toLowerCase()@school.com)
        final email = _generateEmailFromName(name);

        debugPrint('Processing teacher: Name=$name, Department=$department, SubjectIds=$subjectIds');

        // Check if teacher with same email already exists
        final existingTeachers = await _teacherService.getAllTeachers();
        final existingTeacher = existingTeachers.firstWhere(
          (t) => (t['email'] as String).toLowerCase() == email.toLowerCase(),
          orElse: () => {},
        );

        if (existingTeacher.isNotEmpty) {
          // Update existing teacher
          await _teacherService.updateTeacher(
            teacherId: existingTeacher['id'] as String,
            name: name,
            department: department,
            subjectIds: subjectIds,
            password: '123456', // Update password to default
          );
          debugPrint('Updated existing teacher: ${existingTeacher['id']}');
        } else {
          // Create new teacher
          await _teacherService.createTeacher(
            name: name,
            email: email,
            department: department,
            subjectIds: subjectIds,
            password: '123456', // Default password for all teachers
          );
          debugPrint('Created new teacher: $email');
        }

        successCount++;
      } catch (e) {
        errors.add('Row $rowNumber: $e');
        debugPrint('Error processing row $rowNumber: $e');
      }
    }

    return TeacherImportSummary(
      totalRows: rows.length - 1,
      successCount: successCount,
      errorCount: errors.length,
      errors: errors,
    );
  }

  /// Import teachers from Excel file bytes
  ///
  /// Expected header: Name, Department, Subjects
  Future<TeacherImportSummary> importFromExcelBytes(Uint8List excelBytes) async {
    final errors = <String>[];

    try {
      final excel = Excel.decodeBytes(excelBytes);
      if (excel.tables.isEmpty) {
        return const TeacherImportSummary(
          totalRows: 0,
          successCount: 0,
          errorCount: 0,
          errors: ['Excel file has no sheets'],
        );
      }

      final table = excel.tables[excel.tables.keys.first]!;
      if (table.rows.isEmpty) {
        return const TeacherImportSummary(
          totalRows: 0,
          successCount: 0,
          errorCount: 0,
          errors: ['Excel sheet is empty'],
        );
      }

      final header = table.rows[0].map((cell) => cell?.value?.toString().trim() ?? '').toList();
      debugPrint('Excel Header: $header');

      // Find column indices
      final nameIndex = _findColumnIndex(header, ['name']);
      final departmentIndex = _findColumnIndex(header, ['department', 'dept']);
      final subjectsIndex = _findColumnIndex(header, ['subjects', 'subject', 'subjectcodes']);

      if (nameIndex == -1 || departmentIndex == -1 || subjectsIndex == -1) {
        return TeacherImportSummary(
          totalRows: table.rows.length - 1,
          successCount: 0,
          errorCount: table.rows.length - 1,
          errors: [
            'Missing required columns. Found: $header. Required: Name, Department, Subjects'
          ],
        );
      }

      int successCount = 0;
      int rowNumber = 1;

      // Get all subjects once for code-to-ID mapping
      final allSubjects = await _subjectService.getAllSubjects();
      debugPrint('Loaded ${allSubjects.length} subjects for code mapping');

      for (var i = 1; i < table.rows.length; i++) {
        rowNumber++;
        final row = table.rows[i];

        if (row.length < header.length) {
          errors.add('Row $rowNumber: Insufficient columns');
          continue;
        }

        try {
          final name = row[nameIndex]?.value?.toString().trim() ?? '';
          final department = row[departmentIndex]?.value?.toString().trim() ?? '';
          final subjectsStr = row[subjectsIndex]?.value?.toString().trim() ?? '';

          // Validation
          if (name.isEmpty) {
            errors.add('Row $rowNumber: Name is required');
            continue;
          }
          if (department.isEmpty) {
            errors.add('Row $rowNumber: Department is required');
            continue;
          }

          // Parse subject codes and convert to IDs
          final subjectIds = await _parseSubjectCodes(subjectsStr, allSubjects);
          if (subjectsStr.isNotEmpty && subjectIds.isEmpty) {
            // Warning: Subjects not found, but still create teacher with empty subjectIds
            errors.add('Row $rowNumber: Warning - Subject codes "$subjectsStr" not found in database. Teacher created without subjects.');
            debugPrint('Warning: Row $rowNumber - Subject codes "$subjectsStr" not found. Creating teacher without subjects.');
          }

          // Generate email from name
          final email = _generateEmailFromName(name);

          debugPrint('Processing teacher: Name=$name, Department=$department, SubjectIds=$subjectIds');

          // Check if teacher with same email already exists
          final existingTeachers = await _teacherService.getAllTeachers();
          final existingTeacher = existingTeachers.firstWhere(
            (t) => (t['email'] as String).toLowerCase() == email.toLowerCase(),
            orElse: () => {},
          );

          if (existingTeacher.isNotEmpty) {
            await _teacherService.updateTeacher(
              teacherId: existingTeacher['id'] as String,
              name: name,
              department: department,
              subjectIds: subjectIds,
              password: '123456',
            );
            debugPrint('Updated existing teacher: ${existingTeacher['id']}');
          } else {
            await _teacherService.createTeacher(
              name: name,
              email: email,
              department: department,
              subjectIds: subjectIds,
              password: '123456',
            );
            debugPrint('Created new teacher: $email');
          }

          successCount++;
        } catch (e) {
          errors.add('Row $rowNumber: $e');
          debugPrint('Error processing row $rowNumber: $e');
        }
      }

      return TeacherImportSummary(
        totalRows: table.rows.length - 1,
        successCount: successCount,
        errorCount: errors.length,
        errors: errors,
      );
    } catch (e) {
      return TeacherImportSummary(
        totalRows: 0,
        successCount: 0,
        errorCount: 0,
        errors: ['Excel parsing error: $e'],
      );
    }
  }

  /// Create teacher manually (single entry)
  Future<String> createTeacherManually({
    required String name,
    required String department,
    required List<String> subjectCodes, // Subject codes as strings
  }) async {
    try {
      // Get all subjects for code-to-ID mapping
      final allSubjects = await _subjectService.getAllSubjects();
      
      // Parse subject codes and convert to IDs
      final subjectIds = await _parseSubjectCodes(
        subjectCodes.join(','),
        allSubjects,
      );

      // Generate email from name
      final email = _generateEmailFromName(name);

      // Check if teacher with same email already exists
      final existingTeachers = await _teacherService.getAllTeachers();
      final existingTeacher = existingTeachers.firstWhere(
        (t) => (t['email'] as String).toLowerCase() == email.toLowerCase(),
        orElse: () => {},
      );

      if (existingTeacher.isNotEmpty) {
        await _teacherService.updateTeacher(
          teacherId: existingTeacher['id'] as String,
          name: name,
          department: department,
          subjectIds: subjectIds,
          password: '123456',
        );
        return existingTeacher['id'] as String;
      } else {
        return await _teacherService.createTeacher(
          name: name,
          email: email,
          department: department,
          subjectIds: subjectIds,
          password: '123456',
        );
      }
    } catch (e) {
      debugPrint('Error creating teacher manually: $e');
      rethrow;
    }
  }

  /// Helper: Find column index by name (case-insensitive)
  int _findColumnIndex(List<String> headers, List<String> possibleNames) {
    for (final name in possibleNames) {
      final index = headers.indexWhere(
        (h) => h.toLowerCase() == name.toLowerCase(),
      );
      if (index != -1) return index;
    }
    return -1;
  }

  /// Helper: Parse subject codes string and convert to subject IDs
  ///
  /// Input: "CS201,CS202" or "123456" or "CS201, 123456, CS202"
  /// Returns: List of subject document IDs
  Future<List<String>> _parseSubjectCodes(
    String subjectsStr,
    List<Map<String, dynamic>> allSubjects,
  ) async {
    if (subjectsStr.isEmpty) return [];

    // Split by comma and trim
    final codes = subjectsStr
        .split(',')
        .map((code) => code.trim())
        .where((code) => code.isNotEmpty)
        .toList();

    final subjectIds = <String>[];

    for (final code in codes) {
      // Find subject by code (case-insensitive)
      final subject = allSubjects.firstWhere(
        (s) => (s['code'] as String).toUpperCase() == code.toUpperCase(),
        orElse: () => {},
      );

      if (subject.isNotEmpty) {
        subjectIds.add(subject['id'] as String);
        debugPrint('  Mapped subject code "$code" to ID: ${subject['id']}');
      } else {
        debugPrint('  Warning: Subject code "$code" not found');
      }
    }

    return subjectIds;
  }

  /// Helper: Generate email from name
  ///
  /// Format: firstname.lastname@school.com (lowercase, spaces removed/replaced)
  String _generateEmailFromName(String name) {
    // Remove extra spaces and convert to lowercase
    final cleaned = name.trim().toLowerCase();
    
    // Replace spaces with dots, remove special characters
    final emailName = cleaned
        .replaceAll(RegExp(r'\s+'), '.')
        .replaceAll(RegExp(r'[^a-z0-9.]'), '')
        .replaceAll(RegExp(r'\.+'), '.') // Replace multiple dots with single dot
        .replaceAll(RegExp(r'^\.|\.$'), ''); // Remove leading/trailing dots
    
    return '$emailName@school.com';
  }
}

