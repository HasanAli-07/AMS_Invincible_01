/// Attendance Face Recognition Service
/// 
/// This service integrates face recognition with the attendance system.
/// It handles:
/// - Recognizing faces in attendance photos
/// - Matching recognized faces to students
/// - Providing attendance marking suggestions
/// 
/// Usage:
/// ```dart
/// final service = AttendanceFaceRecognitionService();
/// final result = await service.processAttendancePhoto(imageBytes);
/// ```

import 'dart:typed_data';
import 'face_recognition_provider.dart';
import 'face_models.dart';

/// Result of processing an attendance photo
class AttendancePhotoResult {
  final List<RecognizedStudent> recognizedStudents;
  final int totalFacesDetected;
  final int recognizedCount;
  final int unknownCount;

  AttendancePhotoResult({
    required this.recognizedStudents,
    required this.totalFacesDetected,
  }) : recognizedCount = recognizedStudents.where((s) => s.isRecognized).length,
       unknownCount = recognizedStudents.where((s) => !s.isRecognized).length;
}

/// A recognized student from face recognition
class RecognizedStudent {
  final String? studentId;
  final String? studentName;
  final double? confidence; // Similarity score (0.0 to 1.0)
  final bool isRecognized;
  final Rect? faceBoundingBox; // Location of face in image

  RecognizedStudent({
    this.studentId,
    this.studentName,
    this.confidence,
    required this.isRecognized,
    this.faceBoundingBox,
  });
}

class AttendanceFaceRecognitionService {
  /// Process an attendance photo and recognize students
  /// 
  /// Returns list of recognized students with their IDs and confidence scores
  Future<AttendancePhotoResult> processAttendancePhoto({
    required Uint8List imageBytes,
    int imageWidth = 640,
    int imageHeight = 480,
  }) async {
    try {
      // Get face recognition service
      final faceRecognition = FaceRecognitionProvider.instance.service;

      // Recognize faces in the image
      final recognitionResult = await faceRecognition.recognizeFaces(
        imageBytes: imageBytes,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      );

      // Convert to attendance result format
      final recognizedStudents = recognitionResult.recognizedFaces.map((face) {
        if (face.isRecognized && face.match != null) {
          return RecognizedStudent(
            studentId: face.recognizedUserId,
            studentName: face.recognizedUserName,
            confidence: face.match!.similarity,
            isRecognized: true,
            faceBoundingBox: face.detectedFace.boundingBox,
          );
        } else {
          return RecognizedStudent(
            isRecognized: false,
            faceBoundingBox: face.detectedFace.boundingBox,
          );
        }
      }).toList();

      return AttendancePhotoResult(
        recognizedStudents: recognizedStudents,
        totalFacesDetected: recognitionResult.totalFacesDetected,
      );
    } catch (e) {
      // If face recognition fails, return empty result
      return AttendancePhotoResult(
        recognizedStudents: [],
        totalFacesDetected: 0,
      );
    }
  }

  /// Process attendance photo from file path
  Future<AttendancePhotoResult> processAttendancePhotoFromFile(
    String imagePath,
  ) async {
    try {
      final faceRecognition = FaceRecognitionProvider.instance.service;
      final recognitionResult = await faceRecognition.recognizeFacesFromFile(
        imagePath,
      );

      final recognizedStudents = recognitionResult.recognizedFaces.map((face) {
        if (face.isRecognized && face.match != null) {
          return RecognizedStudent(
            studentId: face.recognizedUserId,
            studentName: face.recognizedUserName,
            confidence: face.match!.similarity,
            isRecognized: true,
            faceBoundingBox: face.detectedFace.boundingBox,
          );
        } else {
          return RecognizedStudent(
            isRecognized: false,
            faceBoundingBox: face.detectedFace.boundingBox,
          );
        }
      }).toList();

      return AttendancePhotoResult(
        recognizedStudents: recognizedStudents,
        totalFacesDetected: recognitionResult.totalFacesDetected,
      );
    } catch (e) {
      return AttendancePhotoResult(
        recognizedStudents: [],
        totalFacesDetected: 0,
      );
    }
  }

  /// Check if face recognition is available
  bool get isAvailable => FaceRecognitionProvider.instance.isInitialized;
}

