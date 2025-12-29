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
    // Step 1: Detect faces
    final faces = await _faceDetector.detectFacesFromBytes(
      imageBytes,
      640, // Assume standard camera resolution
      480,
      InputImageRotation.rotation0deg, // Will be properly typed from ML Kit
    );

    if (faces.isEmpty) {
      throw Exception('No face detected in image');
    }

    if (faces.length > 1) {
      throw Exception('Multiple faces detected. Please use an image with only one face.');
    }

    final face = faces.first;

    // Step 2: Check face quality
    if (!face.isAcceptableQuality) {
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
    int imageWidth = 640,
    int imageHeight = 480,
    InputImageRotation rotation = InputImageRotation.rotation0deg,
  }) async {
    // Step 1: Detect all faces
    final detectedFaces = await _faceDetector.detectFacesFromBytes(
      imageBytes,
      imageWidth,
      imageHeight,
      rotation,
    );

    if (detectedFaces.isEmpty) {
      return FaceRecognitionResult(
        recognizedFaces: [],
        totalFacesDetected: 0,
      );
    }

    // Step 2: Get all stored faces for matching
    final storedFaces = await _faceRepository.getAllFaces();

    // Step 3: Process each detected face
    final recognizedFaces = <RecognizedFace>[];

    for (final detectedFace in detectedFaces) {
      // Skip low-quality faces
      if (!detectedFace.isAcceptableQuality) {
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

        recognizedFaces.add(
          RecognizedFace(
            detectedFace: detectedFace,
            match: match,
          ),
        );
      } catch (e) {
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

    final imageBytes = await file.readAsBytes();
    
    // Try to get image dimensions (simplified - in production, use proper image library)
    // For now, assume standard camera resolution
    return await recognizeFaces(
      imageBytes: imageBytes,
      imageWidth: 640,
      imageHeight: 480,
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

