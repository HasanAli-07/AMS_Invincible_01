/// Face Repository for storing and retrieving face embeddings
/// 
/// This repository handles:
/// - Storing face embeddings per user
/// - Retrieving embeddings for matching
/// - Managing multiple embeddings per person (for better accuracy)
/// - Local persistence (in-memory for now, can be extended to SQLite/Hive)

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

