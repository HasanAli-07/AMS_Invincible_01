import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../firebase/services/firestore_student_service.dart';
import '../../firebase/services/firestore_class_service.dart';
import '../../firebase/services/firestore_teacher_service.dart';
import '../../firebase/services/firestore_subject_service.dart';

class BatchUpdateService {
  final FirestoreStudentService _studentService = FirestoreStudentService();
  final FirestoreClassService _classService = FirestoreClassService();
  final FirestoreTeacherService _teacherService = FirestoreTeacherService();
  final FirestoreSubjectService _subjectService = FirestoreSubjectService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update all students, teachers, and subjects to Class 5
  /// and sync them for attendance readiness.
  Future<Map<String, dynamic>> updateAllStudentsToBatch5() async {
    try {
      debugPrint('Starting deep batch update: Syncing all entities to Class 5');

      const targetBatchName = '5';
      const targetDepartment = 'Computer Engineering';
      
      // Step 1: Get or create class with batch = "5"
      String classId;
      final allClasses = await _classService.getAllClasses();
      
      var batch5Class = allClasses.firstWhere(
        (c) => c['name'] == targetBatchName || (c['name'] as String).contains(targetBatchName),
        orElse: () => {},
      );

      if (batch5Class.isEmpty) {
        debugPrint('Creating Class "$targetBatchName" in "$targetDepartment"');
        classId = await _classService.createClass(
          name: targetBatchName,
          department: targetDepartment,
          academicYear: '2024-2025',
          totalStudents: 0,
        );
      } else {
        classId = batch5Class['id'] as String;
        // Update existing class department to ensure match
        await _classService.updateClass(
          classId: classId,
          department: targetDepartment,
        );
        debugPrint('Updated existing class: $classId to $targetDepartment');
      }

      // Step 2: Update ALL Students to Class 5
      final allStudents = await _studentService.getAllStudents();
      debugPrint('Syncing ${allStudents.length} students to Class 5');
      final studentBatch = _firestore.batch();
      for (final student in allStudents) {
        studentBatch.update(
          _firestore.collection('students').doc(student['id'] as String),
          {
            'classId': classId,
            'batch': targetBatchName,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      // Step 3: Update ALL Subjects to target department
      // This ensures they show up for teachers in that department
      final allSubjects = await _subjectService.getAllSubjects();
      debugPrint('Syncing ${allSubjects.length} subjects to $targetDepartment');
      final subjectBatch = _firestore.batch();
      final List<String> subjectIds = [];
      for (final subject in allSubjects) {
        final id = subject['id'] as String;
        subjectIds.add(id);
        subjectBatch.update(
          _firestore.collection('subjects').doc(id),
          {
            'department': targetDepartment,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      // Step 4: Update ALL Teachers to ensure they are linked to Class 5 and all subjects
      final allTeachers = await _teacherService.getAllTeachers();
      debugPrint('Syncing ${allTeachers.length} teachers with Class 5 and subjects');
      final teacherBatch = _firestore.batch();
      for (final teacher in allTeachers) {
        teacherBatch.update(
          _firestore.collection('teachers').doc(teacher['id'] as String),
          {
            'department': targetDepartment,
            'classIds': FieldValue.arrayUnion([classId]),
            'subjectIds': FieldValue.arrayUnion(subjectIds),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      // Commit everything
      await studentBatch.commit();
      await subjectBatch.commit();
      await teacherBatch.commit();
      
      // Update class total students count
      await _classService.updateClass(
        classId: classId,
        totalStudents: allStudents.length,
      );

      debugPrint('Full database sync completed successfully');

      return {
        'success': true,
        'updatedStudents': allStudents.length,
        'updatedSubjects': allSubjects.length,
        'updatedTeachers': allTeachers.length,
        'classId': classId,
      };
    } catch (e) {
      debugPrint('Error in deep batch update: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

