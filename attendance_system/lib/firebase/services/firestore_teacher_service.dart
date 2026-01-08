/// Firestore Teacher Service
/// 
/// Handles teacher data in Firestore
/// 
/// Collection: teachers
/// 
/// Document structure:
/// {
///   name: string
///   email: string
///   department: string
///   subjectIds: string[]
///   classIds: string[]
///   password: string (default: "123456")
///   joinDate: Timestamp
///   createdAt: Timestamp
///   updatedAt: Timestamp
/// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreTeacherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'teachers';

  /// Create teacher document
  Future<String> createTeacher({
    required String name,
    required String email,
    required String department,
    List<String>? subjectIds,
    List<String>? classIds,
    String password = '123456', // Default password for all teachers
    DateTime? joinDate,
  }) async {
    try {
      final teacherData = {
        'name': name,
        'email': email.toLowerCase(),
        'department': department,
        'subjectIds': subjectIds ?? [],
        'classIds': classIds ?? [],
        'password': password, // Store password in Firestore
        'joinDate': joinDate != null
            ? Timestamp.fromDate(joinDate)
            : FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection(_collection).add(teacherData);
      debugPrint('Teacher created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating teacher: $e');
      rethrow;
    }
  }

  /// Get teacher by ID
  Future<Map<String, dynamic>?> getTeacherById(String teacherId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(teacherId).get();
      if (!doc.exists) return null;
      return _documentToMap(doc);
    } catch (e) {
      debugPrint('Error getting teacher: $e');
      rethrow;
    }
  }

  /// Get teachers by department
  Future<List<Map<String, dynamic>>> getTeachersByDepartment(String department) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('department', isEqualTo: department)
          .get();

      return query.docs.map((doc) => _documentToMap(doc)).toList();
    } catch (e) {
      debugPrint('Error getting teachers by department: $e');
      rethrow;
    }
  }

  /// Get all teachers
  Future<List<Map<String, dynamic>>> getAllTeachers() async {
    try {
      final query = await _firestore.collection(_collection).get();
      return query.docs.map((doc) => _documentToMap(doc)).toList();
    } catch (e) {
      debugPrint('Error getting all teachers: $e');
      rethrow;
    }
  }

  /// Update teacher
  Future<void> updateTeacher({
    required String teacherId,
    String? name,
    String? email,
    String? department,
    List<String>? subjectIds,
    List<String>? classIds,
    String? password,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email.toLowerCase();
      if (department != null) updates['department'] = department;
      if (subjectIds != null) updates['subjectIds'] = subjectIds;
      if (classIds != null) updates['classIds'] = classIds;
      if (password != null) updates['password'] = password;

      await _firestore.collection(_collection).doc(teacherId).update(updates);
      debugPrint('Teacher updated: $teacherId');
    } catch (e) {
      debugPrint('Error updating teacher: $e');
      rethrow;
    }
  }

  /// Expose collection name for external services
  String get collectionName => _collection;

  /// Delete teacher
  Future<void> deleteTeacher(String teacherId) async {
    try {
      await _firestore.collection(_collection).doc(teacherId).delete();
      debugPrint('Teacher deleted: $teacherId');
    } catch (e) {
      debugPrint('Error deleting teacher: $e');
      rethrow;
    }
  }

  /// Convert Firestore document to Map
  Map<String, dynamic> _documentToMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return {
      'id': doc.id,
      ...data,
    };
  }
}

