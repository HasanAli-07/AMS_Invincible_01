/// Face Repository for storing and retrieving face embeddings
/// 
/// This repository handles:
/// - Storing face embeddings per user
/// - Retrieving embeddings for matching
/// - Managing multiple embeddings per person (for better accuracy)
/// - Local persistence (in-memory for now, can be extended to SQLite/Hive)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'face_models.dart';

abstract class FaceRepository {
  /// Store a face embedding for a user
  Future<void> storeFace(StoredFace face);

  /// Get all stored faces for a specific user
  Future<List<StoredFace>> getFacesByUserId(String userId);

  /// Get all stored faces
  Future<List<StoredFace>> getAllFaces();

  /// Get face by ID
  Future<StoredFace?> getFaceById(String id);

  /// Delete a stored face
  Future<void> deleteFace(String id);

  /// Delete all faces for a user
  Future<void> deleteFacesByUserId(String userId);

  /// Get count of stored faces
  Future<int> getFaceCount();

  /// Get count of unique users
  Future<int> getUserCount();
}

/// In-memory implementation of FaceRepository
class InMemoryFaceRepository implements FaceRepository {
  final Map<String, StoredFace> _faces = {};
  final Map<String, List<String>> _userFaceIds = {}; // userId -> [faceIds]

  @override
  Future<void> storeFace(StoredFace face) async {
    _faces[face.id] = face;
    _userFaceIds.putIfAbsent(face.userId, () => []).add(face.id);
  }

  @override
  Future<List<StoredFace>> getFacesByUserId(String userId) async {
    final faceIds = _userFaceIds[userId] ?? [];
    return faceIds
        .map((id) => _faces[id])
        .where((face) => face != null)
        .cast<StoredFace>()
        .toList();
  }

  @override
  Future<List<StoredFace>> getAllFaces() async {
    return _faces.values.toList();
  }

  @override
  Future<StoredFace?> getFaceById(String id) async {
    return _faces[id];
  }

  @override
  Future<void> deleteFace(String id) async {
    final face = _faces[id];
    if (face != null) {
      _faces.remove(id);
      _userFaceIds[face.userId]?.remove(id);
      if (_userFaceIds[face.userId]?.isEmpty ?? false) {
        _userFaceIds.remove(face.userId);
      }
    }
  }

  @override
  Future<void> deleteFacesByUserId(String userId) async {
    final faceIds = _userFaceIds[userId] ?? [];
    for (final id in faceIds) {
      _faces.remove(id);
    }
    _userFaceIds.remove(userId);
  }

  @override
  Future<int> getFaceCount() async {
    return _faces.length;
  }

  @override
  Future<int> getUserCount() async {
    return _userFaceIds.length;
  }

  /// Clear all stored faces (for testing/reset)
  Future<void> clearAll() async {
    _faces.clear();
    _userFaceIds.clear();
  }
}

/// Firestore implementation of FaceRepository
class FirestoreFaceRepository implements FaceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'faces';

  @override
  Future<void> storeFace(StoredFace face) async {
    // Convert StoredFace to Map
    // We need to convert FaceEmbedding vector (List<double>) to dynamic for Firestore
    final data = {
      'userId': face.userId,
      'userName': face.userName,
      'embedding': face.embedding.vector,
      'createdAt': Timestamp.fromDate(face.createdAt),
      'imagePath': face.imagePath,
    };

    await _firestore.collection(_collection).doc(face.id).set(data);
  }

  @override
  Future<List<StoredFace>> getFacesByUserId(String userId) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  @override
  Future<List<StoredFace>> getAllFaces() async {
    final snapshot = await _firestore.collection(_collection).get();
    return snapshot.docs.map((doc) => _fromFirestore(doc)).toList();
  }

  @override
  Future<StoredFace?> getFaceById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return _fromFirestore(doc);
  }

  @override
  Future<void> deleteFace(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  @override
  Future<void> deleteFacesByUserId(String userId) async {
    // Firestore doesn't support recursive delete, so we query and delete batch
    final snapshot = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<int> getFaceCount() async {
    final snapshot = await _firestore.collection(_collection).count().get();
    return snapshot.count ?? 0;
  }

  @override
  Future<int> getUserCount() async {
    // Firestore count queries for unique fields are expensive/complex
    // For now, we'll fetch all and count unique userIds locally
    // CAUTION: This is not scalable for huge datasets, but okay for MVP
    final snapshot = await _firestore.collection(_collection).get();
    final userIds = snapshot.docs.map((doc) => doc.data()['userId'] as String).toSet();
    return userIds.length;
  }

  // Helper: Convert Firestore Document to StoredFace
  StoredFace _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    
    // Parse embedding vector
    final embeddingList = List<double>.from(data['embedding'] ?? []);
    final embedding = FaceEmbedding(vector: embeddingList);

    return StoredFace(
      id: doc.id,
      userId: data['userId'] ?? 'unknown',
      userName: data['userName'] ?? 'Unknown User',
      embedding: embedding,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      imagePath: data['imagePath'],
    );
  }
}

