/// Firestore Attendance Service
/// 
/// Handles attendance records in Firestore
/// 
/// Collection: attendance
/// 
/// Document structure:
/// {
///   date: Timestamp
///   subjectId: string
///   classId: string
///   teacherId: string
///   presentStudentIds: string[]
///   absentStudentIds: string[]
///   lateStudentIds: string[]
///   confirmedByTeacher: boolean
///   createdAt: Timestamp
///   updatedAt: Timestamp
/// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/models/attendance_model.dart';

class FirestoreAttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'attendance';

  /// Create attendance session
  Future<String> createAttendanceSession({
    required DateTime date,
    required String subjectId,
    required String classId,
    required String teacherId,
    required List<String> presentStudentIds,
    List<String>? absentStudentIds,
    List<String>? lateStudentIds,
    bool confirmedByTeacher = false,
  }) async {
    try {
      final sessionData = {
        'date': Timestamp.fromDate(date),
        'subjectId': subjectId,
        'classId': classId,
        'teacherId': teacherId,
        'presentStudentIds': presentStudentIds,
        'absentStudentIds': absentStudentIds ?? [],
        'lateStudentIds': lateStudentIds ?? [],
        'confirmedByTeacher': confirmedByTeacher,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection(_collection).add(sessionData);
      debugPrint('Attendance session created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating attendance session: $e');
      rethrow;
    }
  }

  /// Update attendance session
  Future<void> updateAttendanceSession({
    required String sessionId,
    List<String>? presentStudentIds,
    List<String>? absentStudentIds,
    List<String>? lateStudentIds,
    bool? confirmedByTeacher,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (presentStudentIds != null) {
        updates['presentStudentIds'] = presentStudentIds;
      }
      if (absentStudentIds != null) {
        updates['absentStudentIds'] = absentStudentIds;
      }
      if (lateStudentIds != null) {
        updates['lateStudentIds'] = lateStudentIds;
      }
      if (confirmedByTeacher != null) {
        updates['confirmedByTeacher'] = confirmedByTeacher;
      }

      await _firestore.collection(_collection).doc(sessionId).update(updates);
      debugPrint('Attendance session updated: $sessionId');
    } catch (e) {
      debugPrint('Error updating attendance session: $e');
      rethrow;
    }
  }

  /// Get attendance sessions by teacher
  Future<List<Map<String, dynamic>>> getSessionsByTeacher(String teacherId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('teacherId', isEqualTo: teacherId)
          .orderBy('date', descending: true)
          .get();

      return query.docs.map((doc) => _documentToMap(doc)).toList();
    } catch (e) {
      debugPrint('Error getting sessions by teacher: $e');
      rethrow;
    }
  }

  /// Get attendance sessions by class
  Future<List<Map<String, dynamic>>> getSessionsByClass(String classId) async {
    try {
      final query = await _firestore
          .collection(_collection)
          .where('classId', isEqualTo: classId)
          .orderBy('date', descending: true)
          .get();

      return query.docs.map((doc) => _documentToMap(doc)).toList();
    } catch (e) {
      debugPrint('Error getting sessions by class: $e');
      rethrow;
    }
  }

  /// Get attendance sessions by student
  Future<List<Map<String, dynamic>>> getSessionsByStudent(String studentId) async {
    try {
      // Query for sessions where student is in present, absent, or late arrays
      final presentQuery = await _firestore
          .collection(_collection)
          .where('presentStudentIds', arrayContains: studentId)
          .get();

      final absentQuery = await _firestore
          .collection(_collection)
          .where('absentStudentIds', arrayContains: studentId)
          .get();

      final lateQuery = await _firestore
          .collection(_collection)
          .where('lateStudentIds', arrayContains: studentId)
          .get();

      // Combine and deduplicate
      final allDocs = <String, DocumentSnapshot>{};
      for (final doc in presentQuery.docs) {
        allDocs[doc.id] = doc;
      }
      for (final doc in absentQuery.docs) {
        allDocs[doc.id] = doc;
      }
      for (final doc in lateQuery.docs) {
        allDocs[doc.id] = doc;
      }

      return allDocs.values.map((doc) => _documentToMap(doc)).toList()
        ..sort((a, b) {
          final dateA = (a['date'] as Timestamp).toDate();
          final dateB = (b['date'] as Timestamp).toDate();
          return dateB.compareTo(dateA);
        });
    } catch (e) {
      debugPrint('Error getting sessions by student: $e');
      rethrow;
    }
  }

  /// Get attendance session by ID
  Future<Map<String, dynamic>?> getSessionById(String sessionId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(sessionId).get();
      if (!doc.exists) return null;
      return _documentToMap(doc);
    } catch (e) {
      debugPrint('Error getting session: $e');
      rethrow;
    }
  }

  /// Delete attendance session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _firestore.collection(_collection).doc(sessionId).delete();
      debugPrint('Attendance session deleted: $sessionId');
    } catch (e) {
      debugPrint('Error deleting session: $e');
      rethrow;
    }
  }

  /// Stream attendance sessions by class (real-time updates)
  Stream<List<Map<String, dynamic>>> streamSessionsByClass(String classId) {
    return _firestore
        .collection(_collection)
        .where('classId', isEqualTo: classId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => _documentToMap(doc)).toList());
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

