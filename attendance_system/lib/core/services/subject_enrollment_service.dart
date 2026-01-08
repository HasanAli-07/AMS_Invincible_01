/// Subject Enrollment Service
///
/// Handles subject data import from CSV/Excel or manual entry
/// Format: Name, Code, Department, IsLab (0/1)

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../firebase/services/firestore_subject_service.dart';

/// Result summary for subject import
class SubjectImportSummary {
  final int totalRows;
  final int successCount;
  final int errorCount;
  final List<String> errors;

  const SubjectImportSummary({
    required this.totalRows,
    required this.successCount,
    required this.errorCount,
    required this.errors,
  });
}

/// Service for importing subjects from CSV/Excel or manual entry
class SubjectEnrollmentService {
  final FirestoreSubjectService _subjectService;

  SubjectEnrollmentService({FirestoreSubjectService? subjectService})
      : _subjectService = subjectService ?? FirestoreSubjectService();

  /// Import subjects from raw CSV text
  ///
  /// Expected header: Name, Code, Department, IsLab
  /// IsLab: 0 for theory, 1 for lab
  Future<SubjectImportSummary> importFromRawCsv(String csvText) async {
    final errors = <String>[];

    final normalized = csvText.trim();
    if (normalized.isEmpty) {
      return const SubjectImportSummary(
        totalRows: 0,
        successCount: 0,
        errorCount: 0,
        errors: ['CSV is empty'],
      );
    }

    final rows = const CsvToListConverter(eol: '\n').convert(normalized);
    if (rows.isEmpty) {
      return const SubjectImportSummary(
        totalRows: 0,
        successCount: 0,
        errorCount: 0,
        errors: ['CSV has no rows'],
      );
    }

    if (rows.length < 2) {
      return const SubjectImportSummary(
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
    final codeIndex = _findColumnIndex(header, ['code']);
    final departmentIndex = _findColumnIndex(header, ['department', 'dept']);
    final isLabIndex = _findColumnIndex(header, ['islab', 'is_lab', 'lab']);

    if (nameIndex == -1 || codeIndex == -1 || departmentIndex == -1 || isLabIndex == -1) {
      return SubjectImportSummary(
        totalRows: rows.length - 1,
        successCount: 0,
        errorCount: rows.length - 1,
        errors: [
          'Missing required columns. Found: $header. Required: Name, Code, Department, IsLab'
        ],
      );
    }

    int successCount = 0;
    int rowNumber = 1;

    for (var i = 1; i < rows.length; i++) {
      rowNumber++;
      final row = rows[i];

      if (row.length < header.length) {
        errors.add('Row $rowNumber: Insufficient columns (expected ${header.length}, got ${row.length})');
        continue;
      }

      try {
        final name = row[nameIndex]?.toString().trim() ?? '';
        final code = row[codeIndex]?.toString().trim() ?? '';
        final department = row[departmentIndex]?.toString().trim() ?? '';
        final isLabStr = row[isLabIndex]?.toString().trim().toLowerCase() ?? '0';

        // Validation
        if (name.isEmpty) {
          errors.add('Row $rowNumber: Name is required');
          continue;
        }
        if (code.isEmpty) {
          errors.add('Row $rowNumber: Code is required');
          continue;
        }
        if (department.isEmpty) {
          errors.add('Row $rowNumber: Department is required');
          continue;
        }

        // Parse IsLab (accept 0/1, true/false, yes/no)
        final isLab = _parseIsLab(isLabStr);

        debugPrint('Processing subject: Name=$name, Code=$code, Department=$department, IsLab=$isLab');

        // Check if subject with same code already exists
        final existingSubjects = await _subjectService.getAllSubjects();
        final existingSubject = existingSubjects.firstWhere(
          (s) => (s['code'] as String).toUpperCase() == code.toUpperCase(),
          orElse: () => {},
        );

        if (existingSubject.isNotEmpty) {
          // Update existing subject
          await _subjectService.updateSubject(
            subjectId: existingSubject['id'] as String,
            name: name,
            code: code,
            department: department,
            isLab: isLab,
          );
          debugPrint('Updated existing subject: ${existingSubject['id']}');
        } else {
          // Create new subject (default credits to 3 if not provided)
          await _subjectService.createSubject(
            name: name,
            code: code,
            department: department,
            credits: 3, // Default credits
            isLab: isLab,
          );
          debugPrint('Created new subject: $code');
        }

        successCount++;
      } catch (e) {
        errors.add('Row $rowNumber: $e');
        debugPrint('Error processing row $rowNumber: $e');
      }
    }

    return SubjectImportSummary(
      totalRows: rows.length - 1,
      successCount: successCount,
      errorCount: errors.length,
      errors: errors,
    );
  }

  /// Import subjects from Excel file bytes
  ///
  /// Expected header: Name, Code, Department, IsLab
  Future<SubjectImportSummary> importFromExcelBytes(Uint8List excelBytes) async {
    final errors = <String>[];

    try {
      final excel = Excel.decodeBytes(excelBytes);
      if (excel.tables.isEmpty) {
        return const SubjectImportSummary(
          totalRows: 0,
          successCount: 0,
          errorCount: 0,
          errors: ['Excel file has no sheets'],
        );
      }

      final table = excel.tables[excel.tables.keys.first]!;
      if (table.rows.isEmpty) {
        return const SubjectImportSummary(
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
      final codeIndex = _findColumnIndex(header, ['code']);
      final departmentIndex = _findColumnIndex(header, ['department', 'dept']);
      final isLabIndex = _findColumnIndex(header, ['islab', 'is_lab', 'lab']);

      if (nameIndex == -1 || codeIndex == -1 || departmentIndex == -1 || isLabIndex == -1) {
        return SubjectImportSummary(
          totalRows: table.rows.length - 1,
          successCount: 0,
          errorCount: table.rows.length - 1,
          errors: [
            'Missing required columns. Found: $header. Required: Name, Code, Department, IsLab'
          ],
        );
      }

      int successCount = 0;
      int rowNumber = 1;

      for (var i = 1; i < table.rows.length; i++) {
        rowNumber++;
        final row = table.rows[i];

        if (row.length < header.length) {
          errors.add('Row $rowNumber: Insufficient columns');
          continue;
        }

        try {
          final name = row[nameIndex]?.value?.toString().trim() ?? '';
          final code = row[codeIndex]?.value?.toString().trim() ?? '';
          final department = row[departmentIndex]?.value?.toString().trim() ?? '';
          final isLabStr = row[isLabIndex]?.value?.toString().trim().toLowerCase() ?? '0';

          // Validation
          if (name.isEmpty) {
            errors.add('Row $rowNumber: Name is required');
            continue;
          }
          if (code.isEmpty) {
            errors.add('Row $rowNumber: Code is required');
            continue;
          }
          if (department.isEmpty) {
            errors.add('Row $rowNumber: Department is required');
            continue;
          }

          final isLab = _parseIsLab(isLabStr);

          debugPrint('Processing subject: Name=$name, Code=$code, Department=$department, IsLab=$isLab');

          // Check if subject with same code already exists
          final existingSubjects = await _subjectService.getAllSubjects();
          final existingSubject = existingSubjects.firstWhere(
            (s) => (s['code'] as String).toUpperCase() == code.toUpperCase(),
            orElse: () => {},
          );

          if (existingSubject.isNotEmpty) {
            await _subjectService.updateSubject(
              subjectId: existingSubject['id'] as String,
              name: name,
              code: code,
              department: department,
              isLab: isLab,
            );
            debugPrint('Updated existing subject: ${existingSubject['id']}');
          } else {
            await _subjectService.createSubject(
              name: name,
              code: code,
              department: department,
              credits: 3, // Default credits
              isLab: isLab,
            );
            debugPrint('Created new subject: $code');
          }

          successCount++;
        } catch (e) {
          errors.add('Row $rowNumber: $e');
          debugPrint('Error processing row $rowNumber: $e');
        }
      }

      return SubjectImportSummary(
        totalRows: table.rows.length - 1,
        successCount: successCount,
        errorCount: errors.length,
        errors: errors,
      );
    } catch (e) {
      return SubjectImportSummary(
        totalRows: 0,
        successCount: 0,
        errorCount: 0,
        errors: ['Excel parsing error: $e'],
      );
    }
  }

  /// Create subject manually (single entry)
  Future<String> createSubjectManually({
    required String name,
    required String code,
    required String department,
    required bool isLab,
    int credits = 3,
    String? description,
  }) async {
    try {
      // Check if subject with same code already exists
      final existingSubjects = await _subjectService.getAllSubjects();
      final existingSubject = existingSubjects.firstWhere(
        (s) => (s['code'] as String).toUpperCase() == code.toUpperCase(),
        orElse: () => {},
      );

      if (existingSubject.isNotEmpty) {
        await _subjectService.updateSubject(
          subjectId: existingSubject['id'] as String,
          name: name,
          code: code,
          department: department,
          credits: credits,
          isLab: isLab,
          description: description,
        );
        return existingSubject['id'] as String;
      } else {
        return await _subjectService.createSubject(
          name: name,
          code: code,
          department: department,
          credits: credits,
          isLab: isLab,
          description: description,
        );
      }
    } catch (e) {
      debugPrint('Error creating subject manually: $e');
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

  /// Helper: Parse IsLab value (accept 0/1, true/false, yes/no)
  bool _parseIsLab(String value) {
    final normalized = value.toLowerCase().trim();
    if (normalized == '1' || normalized == 'true' || normalized == 'yes') {
      return true;
    }
    if (normalized == '0' || normalized == 'false' || normalized == 'no') {
      return false;
    }
    // Default to false if unclear
    return false;
  }
}

