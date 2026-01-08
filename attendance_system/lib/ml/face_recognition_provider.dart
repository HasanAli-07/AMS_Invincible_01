/// Face Recognition Service Provider
/// 
/// This provides a singleton instance of FaceRecognitionService
/// that can be used throughout the app for face recognition operations.
/// 
/// Usage:
/// ```dart
/// final faceRecognition = FaceRecognitionProvider.instance;
/// await faceRecognition.initialize();
/// ```

import 'face_recognition_service.dart';
import 'face_detector_service.dart';
import 'face_embedding_service.dart';
import 'face_matcher.dart';
import 'face_repository.dart';

class FaceRecognitionProvider {
  static FaceRecognitionProvider? _instance;
  FaceRecognitionService? _service;
  bool _isInitialized = false;

  FaceRecognitionProvider._();

  /// Get singleton instance
  static FaceRecognitionProvider get instance {
    _instance ??= FaceRecognitionProvider._();
    return _instance!;
  }

  /// Initialize face recognition service
  /// 
  /// This should be called once at app startup (e.g., in main.dart)
  /// It loads the TFLite model and sets up all services
  Future<void> initialize({bool useFirestore = true}) async {
    if (_isInitialized && _service != null) {
      return;
    }

    try {
      // Create services
      final faceDetector = FaceDetectorService();
      final embeddingService = FaceEmbeddingService();
      final faceMatcher = FaceMatcher(threshold: 0.70); // 70% similarity threshold

      // Choose repository (Firestore for production, InMemory for testing)
      final FaceRepository faceRepository = useFirestore
          ? FirestoreFaceRepository()
          : InMemoryFaceRepository();

      // Create main service
      _service = FaceRecognitionService(
        faceDetector: faceDetector,
        embeddingService: embeddingService,
        faceMatcher: faceMatcher,
        faceRepository: faceRepository,
      );

      // Initialize (loads TFLite model)
      await _service!.initialize();

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize face recognition: $e');
    }
  }

  /// Get the face recognition service
  /// 
  /// Throws if not initialized
  FaceRecognitionService get service {
    if (!_isInitialized || _service == null) {
      throw Exception(
        'FaceRecognitionService not initialized. '
        'Call FaceRecognitionProvider.instance.initialize() first.',
      );
    }
    return _service!;
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    _service?.dispose();
    _service = null;
    _isInitialized = false;
  }

  /// Reset instance (for testing)
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}

