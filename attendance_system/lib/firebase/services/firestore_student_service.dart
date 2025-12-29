/// Firestore Student Service
/// 
/// Handles student data in Firestore
/// 
/// Collection: students
/// 
/// Document structure:
/// {
///   name: string
///   email: string
///   rollNumber: string
///   classId: string
///   enrollmentDate: Timestamp
///   faceEmbeddings: List<List<double>> (multiple embeddings per student)
///   createdAt: Timestamp
///   updatedAt: Timestamp
/// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreStudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'students';

  /// Expose collection name for external services (e.g., enrollment)
  String get collectionName => _collection;

  /// Create student document
  Future<String> createStudent({
    required String name,
    required String email,
    required String rollNumber,
    required String classId,
    DateTime? enrollmentDate,
  }) async {
    try {
      final studentData = {
        'name': name,
        'email': email.toLowerCase(),
        'rollNumber': rollNumber,
        'classId': classId,
        'enrollmentDate': enrollmentDate != null
            ? Timestamp.fromDate(enrollmentDate)
            : FieldValue.serverTimestamp(),
        'faceEmbeddings': <List<double>>[], // Empty initially
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection(_collection).add(studentData);
      debugPrint('Student created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating student: $e');
      rethrow;
    }
  }

  /// Upsert student with a specific custom ID (e.g., CSV student_id)
  ///
  /// This is used for bulk enrollment where student_id is stable and
  /// must match folder names in the ZIP face enrollment stage.
  Future<void> upsertStudentWithId({
    required String studentId,
    required String name,
    required String rollNumber,
    required String classId,
    String? email,
  }) async {
    try {
      final docRef = _firestore.collection(_collection).doc(studentId);
      final existing = await docRef.get();

      final baseData = {
        'name': name,
        'email': (email ?? '').toLowerCase(),
        'rollNumber': rollNumber,
        'classId': classId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (existing.exists) {
        // Merge into existing student document
        await docRef.update(baseData);
      } else {
        // Create new student with stable ID and empty embeddings
        await docRef.set({
          ...baseData,
          'enrollmentDate': FieldValue.serverTimestamp(),
          'faceEmbeddings': <List<double>>[],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('Student upserted with custom ID: $studentId');
    } catch (e) {
      debugPrint('Error upserting student with custom ID: $e');
      rethrow;
    }
  }

  /// Add face embedding to student
  /// 
  /// Stores embeddings as List<double> in faceEmbeddings array
  /// Multiple embeddings per student for better recognition accuracy
  Future<void> addFaceEmbedding({
    required String studentId,
    required List<double> embedding,
  }) async {
    try {
      await _firestore.collection(_collection).doc(studentId).update({
        'faceEmbeddings': FieldValue.arrayUnion([embedding]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Face embedding added to student: $studentId');
    } catch (e) {
      debugPrint('Error adding face embedding: $e');
      rethrow;
    }
  }

  /// Get student by ID
  Future<Map<String, dynamic>?> getStudentById(String studentId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(studentId).get();
      if (!doc.exists) return null;
      return _documentToMap(doc);
    } catch (e) {
      debugPrint('Error getting student: $e');
      rethrow;
    }
  }

  /// Get students by class
  Future<List<Map<String, dynamic>>> getStudentsByClass(String classId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('classId', isEqualTo: classId)
          .get();

      return query.docs.map((doc) => _documentToMap(doc)).toList();
    } catch (e) {
      debugPrint('Error getting students by class: $e');
      rethrow;
    }
  }

  /// Get all students
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    try {
      final query = await _firestore.collection(_collection).get();
      return query.docs.map((doc) => _documentToMap(doc)).toList();
    } catch (e) {
      debugPrint('Error getting all students: $e');
      rethrow;
    }
  }

  /// Update student
  Future<void> updateStudent({
    required String studentId,
    String? name,
    String? email,
    String? rollNumber,
    String? classId,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email.toLowerCase();
      if (rollNumber != null) updates['rollNumber'] = rollNumber;
      if (classId != null) updates['classId'] = classId;

      await _firestore.collection(_collection).doc(studentId).update(updates);
      debugPrint('Student updated: $studentId');
    } catch (e) {
      debugPrint('Error updating student: $e');
      rethrow;
    }
  }

  /// Delete student
  Future<void> deleteStudent(String studentId) async {
    try {
      await _firestore.collection(_collection).doc(studentId).delete();
      debugPrint('Student deleted: $studentId');
    } catch (e) {
      debugPrint('Error deleting student: $e');
      rethrow;
    }
  }

  /// Batch import students from CSV data
  Future<List<String>> importStudentsFromCSV({
    required List<Map<String, String>> csvData,
    required String classId,
  }) async {
    try {
      final batch = _firestore.batch();
      final studentIds = <String>[];

      for (final row in csvData) {
        final docRef = _firestore.collection(_collection).doc();
        studentIds.add(docRef.id);

        final studentData = {
          'name': row['name'] ?? '',
          'email': (row['email'] ?? '').toLowerCase(),
          'rollNumber': row['rollNumber'] ?? '',
          'classId': classId,
          'enrollmentDate': FieldValue.serverTimestamp(),
          'faceEmbeddings': <List<double>>[],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        batch.set(docRef, studentData);
      }

      await batch.commit();
      debugPrint('Imported ${studentIds.length} students');
      return studentIds;
    } catch (e) {
      debugPrint('Error importing students: $e');
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

