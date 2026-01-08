/// Firestore Subject Service
/// 
/// Handles subject data in Firestore
/// 
/// Collection: subjects
/// 
/// Document structure:
/// {
///   name: string
///   code: string
///   department: string
///   credits: number
///   isLab: boolean (true for lab, false for theory)
///   description: string?
///   createdAt: Timestamp
///   updatedAt: Timestamp
/// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreSubjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'subjects';

  /// Create subject document
  Future<String> createSubject({
    required String name,
    required String code,
    required String department,
    required int credits,
    required bool isLab,
    String? description,
  }) async {
    try {
      final subjectData = {
        'name': name,
        'code': code.toUpperCase(),
        'department': department,
        'credits': credits,
        'isLab': isLab,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection(_collection).add(subjectData);
      debugPrint('Subject created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating subject: $e');
      rethrow;
    }
  }

  /// Get subject by ID
  Future<Map<String, dynamic>?> getSubjectById(String subjectId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(subjectId).get();
      if (!doc.exists) return null;
      return _documentToMap(doc);
    } catch (e) {
      debugPrint('Error getting subject: $e');
      rethrow;
    }
  }

  /// Get subjects by department
  Future<List<Map<String, dynamic>>> getSubjectsByDepartment(String department) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('department', isEqualTo: department)
          .get();

      return query.docs.map((doc) => _documentToMap(doc)).toList();
    } catch (e) {
      debugPrint('Error getting subjects by department: $e');
      rethrow;
    }
  }

  /// Get all subjects
  Future<List<Map<String, dynamic>>> getAllSubjects() async {
    try {
      final query = await _firestore.collection(_collection).get();
      return query.docs.map((doc) => _documentToMap(doc)).toList();
    } catch (e) {
      debugPrint('Error getting all subjects: $e');
      rethrow;
    }
  }

  /// Update subject
  Future<void> updateSubject({
    required String subjectId,
    String? name,
    String? code,
    String? department,
    int? credits,
    bool? isLab,
    String? description,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (code != null) updates['code'] = code.toUpperCase();
      if (department != null) updates['department'] = department;
      if (credits != null) updates['credits'] = credits;
      if (isLab != null) updates['isLab'] = isLab;
      if (description != null) updates['description'] = description;

      await _firestore.collection(_collection).doc(subjectId).update(updates);
      debugPrint('Subject updated: $subjectId');
    } catch (e) {
      debugPrint('Error updating subject: $e');
      rethrow;
    }
  }

  /// Delete subject
  Future<void> deleteSubject(String subjectId) async {
    try {
      await _firestore.collection(_collection).doc(subjectId).delete();
      debugPrint('Subject deleted: $subjectId');
    } catch (e) {
      debugPrint('Error deleting subject: $e');
      rethrow;
    }
  }

  /// Convert Firestore document to Map
  Map<String, dynamic> _documentToMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return {
      'id': doc.id,
      ...data,
      // Ensure isLab defaults to false if not present (for backward compatibility)
      'isLab': data['isLab'] ?? false,
    };
  }

  /// Expose collection name for external services
  String get collectionName => _collection;
}

