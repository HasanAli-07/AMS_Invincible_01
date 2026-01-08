/// Face Recognition Service - Complete Pipeline
/// 
/// This is the main service that orchestrates the entire face recognition pipeline:
/// 
/// 1. Face Detection (ML Kit)
/// 2. Face Cropping & Preprocessing
/// 3. Face Embedding Generation (TFLite)
/// 4. Face Matching (Cosine Similarity)
/// 5. Result Aggregation
/// 
/// This service provides a high-level API for face recognition in the attendance system.

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'face_detector_service.dart';
import 'face_embedding_service.dart';
import 'face_matcher.dart';
import 'face_repository.dart';
import 'face_models.dart';

class FaceRecognitionService {
  final FaceDetectorService _faceDetector;
  final FaceEmbeddingService _embeddingService;
  final FaceMatcher _faceMatcher;
  final FaceRepository _faceRepository;

  FaceRecognitionService({
    required FaceDetectorService faceDetector,
    required FaceEmbeddingService embeddingService,
    required FaceMatcher faceMatcher,
    required FaceRepository faceRepository,
  })  : _faceDetector = faceDetector,
        _embeddingService = embeddingService,
        _faceMatcher = faceMatcher,
        _faceRepository = faceRepository;

  /// Initialize the service (load TFLite model)
  Future<void> initialize() async {
    await _embeddingService.initialize();
  }

  /// Register a face for a user (enrollment)
  /// 
  /// This is used when adding a new student/teacher to the system
  /// Takes an image, detects face, generates embedding, and stores it
  Future<StoredFace> registerFace({
    required String userId,
    required String userName,
    required Uint8List imageBytes,
    String? imagePath,
  }) async {
    // Step 1: Detect faces using encoding-aware detection (handles JPEG/PNG)
    final faces = await _faceDetector.detectFacesFromEncodedBytes(imageBytes);

    if (faces.isEmpty) {
      throw Exception('No face detected in image');
    }

    if (faces.length > 1) {
      throw Exception('Multiple faces detected. Please use an image with only one face.');
    }

    final face = faces.first;

    // Step 2: Check face quality (strict for registration)
    if (!face.isAcceptableQuality(strict: true)) {
      throw Exception(
        'Face quality is not acceptable. Please ensure:\n'
        '- Face is clearly visible\n'
        '- Head is not rotated too much\n'
        '- Eyes are open',
      );
    }

    // Step 3: Crop face
    const targetSize = 112; // Standard size for face recognition models
    final croppedFace = await _faceDetector.cropFace(
      imageBytes,
      face,
      targetSize,
    );

    // Step 4: Generate embedding
    final embedding = await _embeddingService.generateEmbedding(croppedFace);

    // Step 5: Store embedding
    final storedFace = StoredFace(
      id: 'face_${DateTime.now().millisecondsSinceEpoch}_${userId}',
      userId: userId,
      userName: userName,
      embedding: embedding,
      createdAt: DateTime.now(),
      imagePath: imagePath,
    );

    await _faceRepository.storeFace(storedFace);

    return storedFace;
  }

  /// Recognize faces in an image (attendance marking)
  /// 
  /// This is used during attendance marking:
  /// - Detects all faces in the image
  /// - Generates embeddings for each face
  /// - Matches against stored faces
  /// - Returns recognition results
  Future<FaceRecognitionResult> recognizeFaces({
    required Uint8List imageBytes,
    int? imageWidth,
    int? imageHeight,
    InputImageRotation rotation = InputImageRotation.rotation0deg,
  }) async {
    // Step 1: Detect all faces
    // If width/height not provided, assume encoded bytes (JPEG/PNG)
    final List<DetectedFace> detectedFaces;
    if (imageWidth == null || imageHeight == null) {
      detectedFaces = await _faceDetector.detectFacesFromEncodedBytes(imageBytes);
    } else {
      detectedFaces = await _faceDetector.detectFacesFromBytes(
        imageBytes,
        imageWidth,
        imageHeight,
        rotation,
      );
    }

    if (detectedFaces.isEmpty) {
      return FaceRecognitionResult(
        recognizedFaces: [],
        totalFacesDetected: 0,
      );
    }

    // Step 2: Get all stored faces for matching
    final storedFaces = await _faceRepository.getAllFaces();
    debugPrint('Face Recognition: Processing ${detectedFaces.length} faces against ${storedFaces.length} stored embeddings');

    // Step 3: Process each detected face
    final recognizedFaces = <RecognizedFace>[];

    for (final detectedFace in detectedFaces) {
      // Skip low-quality faces (lenient for recognition)
      if (!detectedFace.isAcceptableQuality(strict: false)) {
        recognizedFaces.add(
          RecognizedFace(
            detectedFace: detectedFace,
            match: null,
          ),
        );
        continue;
      }

      try {
        // Crop face
        const targetSize = 112;
        final croppedFace = await _faceDetector.cropFace(
          imageBytes,
          detectedFace,
          targetSize,
        );

        // Generate embedding
        final embedding = await _embeddingService.generateEmbedding(croppedFace);

        // Find best match
        final match = _faceMatcher.findBestMatch(embedding, storedFaces);

        if (match != null && match.isMatch) {
          debugPrint('✅ Face Match found! Student: ${match.matchedFace.userId} (${match.matchedFace.userName}), Similarity: ${match.similarity.toStringAsFixed(3)}');
        } else if (match != null) {
          debugPrint('❌ No high-confidence match. Best guess: ${match.matchedFace.userId}, Similarity: ${match.similarity.toStringAsFixed(3)} (Threshold: ${_faceMatcher.threshold})');
        }

        recognizedFaces.add(
          RecognizedFace(
            detectedFace: detectedFace,
            match: match,
          ),
        );
      } catch (e) {
        debugPrint('⚠️ Error processing detected face: $e');
        // If processing fails, add as unrecognized
        recognizedFaces.add(
          RecognizedFace(
            detectedFace: detectedFace,
            match: null,
          ),
        );
      }
    }

    return FaceRecognitionResult(
      recognizedFaces: recognizedFaces,
      totalFacesDetected: detectedFaces.length,
    );
  }

  /// Recognize faces from image file
  Future<FaceRecognitionResult> recognizeFacesFromFile(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Image file not found: $imagePath');
    }

    // Use ML Kit's fromFilePath for better accuracy and automatic format handling
    final detectedFaces = await _faceDetector.detectFacesFromFile(imagePath);
    
    if (detectedFaces.isEmpty) {
      return FaceRecognitionResult(
        recognizedFaces: [],
        totalFacesDetected: 0,
      );
    }

    final imageBytes = await file.readAsBytes();
    final storedFaces = await _faceRepository.getAllFaces();
    final recognizedFaces = <RecognizedFace>[];

    for (final detectedFace in detectedFaces) {
      // For recognition, we can be slightly more lenient with quality than for enrollment
      // but still filter out extreme cases
      try {
        const targetSize = 112;
        final croppedFace = await _faceDetector.cropFace(
          imageBytes,
          detectedFace,
          targetSize,
        );

        final embedding = await _embeddingService.generateEmbedding(croppedFace);
        final match = _faceMatcher.findBestMatch(embedding, storedFaces);

        if (match != null && match.isMatch) {
          debugPrint('✅ Face [File] Match found! Student: ${match.matchedFace.userId} (${match.matchedFace.userName}), Similarity: ${match.similarity.toStringAsFixed(3)}');
        } else if (match != null) {
          debugPrint('❌ Face [File] Low confidence: guess ${match.matchedFace.userId}, score: ${match.similarity.toStringAsFixed(3)} (Threshold: ${_faceMatcher.threshold})');
        }

        recognizedFaces.add(
          RecognizedFace(
            detectedFace: detectedFace,
            match: match,
          ),
        );
      } catch (e) {
        recognizedFaces.add(
          RecognizedFace(
            detectedFace: detectedFace,
            match: null,
          ),
        );
      }
    }

    return FaceRecognitionResult(
      recognizedFaces: recognizedFaces,
      totalFacesDetected: detectedFaces.length,
    );
  }

  /// Get all registered faces for a user
  Future<List<StoredFace>> getUserFaces(String userId) async {
    return await _faceRepository.getFacesByUserId(userId);
  }

  /// Delete all faces for a user
  Future<void> deleteUserFaces(String userId) async {
    await _faceRepository.deleteFacesByUserId(userId);
  }

  /// Delete all registered faces
  Future<void> deleteAllFaces() async {
    await _faceRepository.deleteAllFaces();
  }

  /// Get recognition statistics
  Future<Map<String, dynamic>> getStatistics() async {
    final totalFaces = await _faceRepository.getFaceCount();
    final totalUsers = await _faceRepository.getUserCount();

    return {
      'totalFaces': totalFaces,
      'totalUsers': totalUsers,
      'threshold': _faceMatcher.getThreshold(),
      'isModelLoaded': _embeddingService.isInitialized,
    };
  }

  /// Dispose resources
  void dispose() {
    _faceDetector.dispose();
    _embeddingService.dispose();
  }
}

