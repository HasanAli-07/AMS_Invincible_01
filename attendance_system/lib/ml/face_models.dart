/// Face Recognition Models
/// 
/// This file contains data models for face recognition pipeline:
/// - DetectedFace: Face detected by ML Kit
/// - FaceEmbedding: Numerical representation of a face
/// - FaceMatch: Result of face matching
/// - FaceRecognitionResult: Complete recognition result

import 'dart:typed_data';
import 'dart:math' as math;

/// Represents a detected face with bounding box and metadata
class DetectedFace {
  final Rect boundingBox;
  final double? leftEyeOpenProbability;
  final double? rightEyeOpenProbability;
  final double? smilingProbability;
  final double? headEulerAngleY; // Head rotation
  final double? headEulerAngleZ;

  const DetectedFace({
    required this.boundingBox,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    this.smilingProbability,
    this.headEulerAngleY,
    this.headEulerAngleZ,
  });

  /// Check if face quality is acceptable for recognition
  /// Reject faces that are too rotated or eyes are closed
  /// [strict] if true, uses strict rules (recommended for registration)
  bool isAcceptableQuality({bool strict = false}) {
    // Rotation limit: 45 degrees for recognition, 30 for registration
    final rotationLimit = strict ? 30 : 45;
    
    if (headEulerAngleY != null && headEulerAngleY!.abs() > rotationLimit) {
      return false;
    }
    if (headEulerAngleZ != null && headEulerAngleZ!.abs() > rotationLimit) {
      return false;
    }
    
    // For registration, we want eyes open
    if (strict && leftEyeOpenProbability != null && 
        rightEyeOpenProbability != null &&
        leftEyeOpenProbability! < 0.3 && 
        rightEyeOpenProbability! < 0.3) {
      return false;
    }
    
    return true;
  }
}

/// Bounding box for detected face
class Rect {
  final double left;
  final double top;
  final double right;
  final double bottom;
  final double width;
  final double height;

  const Rect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  }) : width = right - left,
       height = bottom - top;

  /// Get center point
  Point get center => Point(
    x: left + width / 2,
    y: top + height / 2,
  );
}

/// Point coordinates
class Point {
  final double x;
  final double y;

  const Point({required this.x, required this.y});
}

/// Face embedding - numerical representation of a face
/// This is a vector of floats (typically 128 or 512 dimensions)
/// that uniquely represents a face's features
class FaceEmbedding {
  final List<double> vector;
  final int dimension;

  const FaceEmbedding({
    required this.vector,
  }) : dimension = vector.length;

  /// Normalize the embedding vector (L2 normalization)
  /// This is critical for cosine similarity to work correctly
  FaceEmbedding normalized() {
    final magnitude = _calculateMagnitude(vector);
    if (magnitude == 0.0) return this;
    
    final normalized = vector.map((v) => v / magnitude).toList();
    return FaceEmbedding(vector: normalized);
  }

  double _calculateMagnitude(List<double> vec) {
    double sum = 0.0;
    for (final v in vec) {
      sum += v * v;
    }
    return math.sqrt(sum);
  }
}

/// Stored face data for a user
class StoredFace {
  final String id;
  final String userId; // Student/User ID
  final String userName;
  final FaceEmbedding embedding;
  final DateTime createdAt;
  final String? imagePath; // Optional: for debugging

  const StoredFace({
    required this.id,
    required this.userId,
    required this.userName,
    required this.embedding,
    required this.createdAt,
    this.imagePath,
  });

  StoredFace copyWith({
    String? id,
    String? userId,
    String? userName,
    FaceEmbedding? embedding,
    DateTime? createdAt,
    String? imagePath,
  }) {
    return StoredFace(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      embedding: embedding ?? this.embedding,
      createdAt: createdAt ?? this.createdAt,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

/// Face matching result
class FaceMatch {
  final StoredFace matchedFace;
  final double similarity; // Cosine similarity score (0.0 to 1.0)
  final bool isMatch; // True if similarity > threshold

  const FaceMatch({
    required this.matchedFace,
    required this.similarity,
    required this.isMatch,
  });
}

/// Complete face recognition result for an image
class FaceRecognitionResult {
  final List<RecognizedFace> recognizedFaces;
  final int totalFacesDetected;
  final int recognizedCount;
  final int unknownCount;

  FaceRecognitionResult({
    required this.recognizedFaces,
    required this.totalFacesDetected,
  }) : recognizedCount = recognizedFaces.where((f) => f.isRecognized).length,
       unknownCount = recognizedFaces.where((f) => !f.isRecognized).length;
}

/// Single recognized face in an image
class RecognizedFace {
  final DetectedFace detectedFace;
  final FaceMatch? match; // null if unknown
  final bool isRecognized;
  final String? recognizedUserId;
  final String? recognizedUserName;

  RecognizedFace({
    required this.detectedFace,
    this.match,
  }) : isRecognized = match != null && match.isMatch,
       recognizedUserId = match?.matchedFace.userId,
       recognizedUserName = match?.matchedFace.userName;
}

