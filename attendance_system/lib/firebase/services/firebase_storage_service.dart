/// Firebase Storage Service
/// 
/// Handles file storage in Firebase Storage
/// 
/// IMPORTANT: Storage is OPTIONAL and works on FREE Spark plan!
/// If you see "upgrade billing" message, it's likely Storage isn't enabled yet.
/// 
/// FREE TIER LIMITS:
/// - 5 GB storage
/// - 1 GB/day downloads
/// 
/// Usage:
/// - Store temporary student images (for face enrollment)
/// - Store profile pictures (light use)
/// - NO permanent raw image storage (use embeddings instead)
/// 
/// NOTE: This service gracefully handles cases where Storage isn't available.
/// The app will work fine without Storage - face recognition uses embeddings only.

import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseStorageService {
  final FirebaseStorage? _storage;
  late final bool _isAvailable;

  /// Create Storage Service
  ///
  /// If Storage isn't available (not enabled in Firebase),
  /// service will work in safe mode (no-op operations)
  FirebaseStorageService() : _storage = _tryGetStorage() {
    _isAvailable = _storage != null;
  }

  /// Try to get Storage instance
  /// Returns null if Storage isn't available
  static FirebaseStorage? _tryGetStorage() {
    try {
      return FirebaseStorage.instance;
    } catch (e) {
      debugPrint('Firebase Storage not available: $e');
      debugPrint('App will work without Storage. Face recognition uses embeddings only.');
      return null;
    }
  }

  /// Check if Storage is available
  bool get isAvailable => _isAvailable;

  /// Upload image file
  /// 
  /// Path format: 'students/{studentId}/enrollment/{timestamp}.jpg'
  /// 
  /// Returns download URL
  /// 
  /// NOTE: If Storage isn't available, returns empty string (no error thrown)
  Future<String> uploadImage({
    required String path,
    required Uint8List imageBytes,
    String? contentType,
  }) async {
    if (!_isAvailable || _storage == null) {
      debugPrint('Storage not available - skipping upload: $path');
      debugPrint('Face recognition will work with embeddings only.');
      return ''; // Return empty string instead of throwing error
    }

    try {
      final ref = _storage!.ref().child(path);
      
      final metadata = SettableMetadata(
        contentType: contentType ?? 'image/jpeg',
        cacheControl: 'max-age=3600', // Cache for 1 hour
      );

      final uploadTask = ref.putData(imageBytes, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Image uploaded: $path');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      debugPrint('Continuing without Storage - app will work fine.');
      return ''; // Don't throw - app works without Storage
    }
  }

  /// Upload student enrollment image
  /// 
  /// Stores temporarily for face enrollment process
  /// Should be deleted after embedding is generated
  Future<String> uploadStudentEnrollmentImage({
    required String studentId,
    required Uint8List imageBytes,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'students/$studentId/enrollment/$timestamp.jpg';
    return await uploadImage(
      path: path,
      imageBytes: imageBytes,
      contentType: 'image/jpeg',
    );
  }

  /// Upload profile picture
  /// 
  /// Light use only - small file sizes
  Future<String> uploadProfilePicture({
    required String userId,
    required Uint8List imageBytes,
  }) async {
    final path = 'profiles/$userId/profile.jpg';
    return await uploadImage(
      path: path,
      imageBytes: imageBytes,
      contentType: 'image/jpeg',
    );
  }

  /// Delete file
  /// 
  /// NOTE: If Storage isn't available, does nothing (no error)
  Future<void> deleteFile(String path) async {
    if (!_isAvailable || _storage == null) {
      debugPrint('Storage not available - skipping delete: $path');
      return;
    }

    try {
      await _storage!.ref().child(path).delete();
      debugPrint('File deleted: $path');
    } catch (e) {
      debugPrint('Error deleting file: $e');
      // Don't throw - app works without Storage
    }
  }

  /// Get download URL
  /// 
  /// NOTE: If Storage isn't available, returns empty string
  Future<String> getDownloadUrl(String path) async {
    if (!_isAvailable || _storage == null) {
      debugPrint('Storage not available - cannot get URL: $path');
      return '';
    }

    try {
      return await _storage!.ref().child(path).getDownloadURL();
    } catch (e) {
      debugPrint('Error getting download URL: $e');
      return ''; // Return empty instead of throwing
    }
  }

  /// Delete student enrollment images
  /// 
  /// Cleanup after face enrollment is complete
  /// 
  /// NOTE: If Storage isn't available, does nothing (no error)
  Future<void> deleteStudentEnrollmentImages(String studentId) async {
    if (!_isAvailable || _storage == null) {
      debugPrint('Storage not available - skipping cleanup for student: $studentId');
      return;
    }

    try {
      final ref = _storage!.ref().child('students/$studentId/enrollment');
      final listResult = await ref.listAll();

      for (final item in listResult.items) {
        await item.delete();
      }

      debugPrint('Deleted enrollment images for student: $studentId');
    } catch (e) {
      debugPrint('Error deleting enrollment images: $e');
      // Don't throw - app works without Storage
    }
  }
}

