import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:attendance_system/core/data/local_enrollment_db_helper.dart';
import 'package:attendance_system/core/services/student_enrollment_service.dart';

import 'package:attendance_system/firebase/services/firestore_student_service.dart';
import 'package:mockito/mockito.dart';

class MockStudentService extends Mock implements FirestoreStudentService {
  @override
  Future<void> upsertStudentWithId({
    required String studentId,
    required String name,
    required String rollNumber,
    required String classId,
    String? email,
  }) async {
    // Mock success
    return Future.value();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Student Enrollment Tests', () {
    test('CSV Import parses correctly and saves to SQLite', () async {
      final mockStudentService = MockStudentService();
      final service = StudentCsvEnrollmentService(studentService: mockStudentService);
      final csvData = '''
Name,EnrollmentNo,Semester,Department,Batch
John Doe,S101,4,CS,A1
Jane Smith,S102,6,IT,B2
      ''';

      final summary = await service.importFromRawCsv(csvData);

      expect(summary.successCount, 2);
      expect(summary.errorCount, 0);

      // Check SQLite
      final dbHelper = LocalEnrollmentDbHelper.instance;
      final pending = await dbHelper.getPendingStudents();
      
      expect(pending.length, 2);
      expect(pending[0]['name'], 'John Doe');
      expect(pending[0]['enrollment_no'], 'S101');
      expect(pending[0]['batch'], 'A1');
    });
  });
}
