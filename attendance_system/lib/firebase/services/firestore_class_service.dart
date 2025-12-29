/// Firestore Class Service
/// 
/// Handles academic unit/class data in Firestore
/// 
/// Collection: academic_units
/// 
/// Document structure:
/// {
///   name: string (e.g., "10-A", "CS-2024")
///   department: string
///   academicYear: string
///   totalStudents: number
///   classTeacherId: string?
///   createdAt: Timestamp
///   updatedAt: Timestamp
/// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'academic_units';

  /// Create class document
  Future<String> createClass({
    required String name,
    required String department,
    required String academicYear,
    int? totalStudents,
    String? classTeacherId,
  }) async {
    try {
      final classData = {
        'name': name,
        'department': department,
        'academicYear': academicYear,
        'totalStudents': totalStudents ?? 0,
        'classTeacherId': classTeacherId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection(_collection).add(classData);
      debugPrint('Class created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating class: $e');
      rethrow;
    }
  }

  /// Get class by ID
  Future<Map<String, dynamic>?> getClassById(String classId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(classId).get();
      if (!doc.exists) return null;
      return _documentToMap(doc);
    } catch (e) {
      debugPrint('Error getting class: $e');
      rethrow;
    }
  }

  /// Get classes by department
  Future<List<Map<String, dynamic>>> getClassesByDepartment(String department) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('department', isEqualTo: department)
          .get();

      return query.docs.map((doc) => _documentToMap(doc)).toList();
    } catch (e) {
      debugPrint('Error getting classes by department: $e');
      rethrow;
    }
  }

  /// Get all classes
  Future<List<Map<String, dynamic>>> getAllClasses() async {
    try {
      final query = await _firestore.collection(_collection).get();
      return query.docs.map((doc) => _documentToMap(doc)).toList();
    } catch (e) {
      debugPrint('Error getting all classes: $e');
      rethrow;
    }
  }

  /// Update class
  Future<void> updateClass({
    required String classId,
    String? name,
    String? department,
    String? academicYear,
    int? totalStudents,
    String? classTeacherId,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (department != null) updates['department'] = department;
      if (academicYear != null) updates['academicYear'] = academicYear;
      if (totalStudents != null) updates['totalStudents'] = totalStudents;
      if (classTeacherId != null) updates['classTeacherId'] = classTeacherId;

      await _firestore.collection(_collection).doc(classId).update(updates);
      debugPrint('Class updated: $classId');
    } catch (e) {
      debugPrint('Error updating class: $e');
      rethrow;
    }
  }

  /// Delete class
  Future<void> deleteClass(String classId) async {
    try {
      await _firestore.collection(_collection).doc(classId).delete();
      debugPrint('Class deleted: $classId');
    } catch (e) {
      debugPrint('Error deleting class: $e');
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

