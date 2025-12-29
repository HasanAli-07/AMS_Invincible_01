/// Example Usage of Face Recognition Service
/// 
/// This file demonstrates how to use the face recognition system
/// for enrollment and attendance marking.

import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'face_recognition_service.dart';
import 'face_detector_service.dart';
import 'face_embedding_service.dart';
import 'face_matcher.dart';
import 'face_repository.dart';

class FaceRecognitionExample {
  late final FaceRecognitionService _faceRecognition;

  /// Initialize the face recognition system
  Future<void> initialize() async {
    // Create services
    final faceDetector = FaceDetectorService();
    final embeddingService = FaceEmbeddingService();
    final faceMatcher = FaceMatcher(threshold: 0.70); // 70% similarity threshold
    final faceRepository = InMemoryFaceRepository();

    // Create main service
    _faceRecognition = FaceRecognitionService(
      faceDetector: faceDetector,
      embeddingService: embeddingService,
      faceMatcher: faceMatcher,
      faceRepository: faceRepository,
    );

    // Initialize (loads TFLite model)
    await _faceRecognition.initialize();
  }

  /// Example: Register a student's face
  Future<void> registerStudentFace({
    required String studentId,
    required String studentName,
  }) async {
    try {
      // Pick image from gallery or camera
      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.camera, // or ImageSource.gallery
      );

      if (pickedFile == null) return;

      // Read image bytes
      final imageBytes = await pickedFile.readAsBytes();

      // Register face
      final storedFace = await _faceRecognition.registerFace(
        userId: studentId,
        userName: studentName,
        imageBytes: imageBytes,
        imagePath: pickedFile.path,
      );

      print('Face registered successfully!');
      print('Face ID: ${storedFace.id}');
      print('User: ${storedFace.userName}');
    } catch (e) {
      print('Registration failed: $e');
      // Handle error (show dialog, etc.)
    }
  }

  /// Example: Mark attendance using face recognition
  Future<Map<String, bool>> markAttendanceFromPhoto() async {
    try {
      // Take photo or pick from gallery
      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(
        source: ImageSource.camera,
      );

      if (pickedFile == null) {
        return {};
      }

      // Read image bytes
      final imageBytes = await pickedFile.readAsBytes();

      // Recognize faces
      final result = await _faceRecognition.recognizeFaces(
        imageBytes: imageBytes,
        imageWidth: 640,
        imageHeight: 480,
      );

      print('Total faces detected: ${result.totalFacesDetected}');
      print('Recognized: ${result.recognizedCount}');
      print('Unknown: ${result.unknownCount}');

      // Build attendance map
      final attendance = <String, bool>{};

      for (final recognizedFace in result.recognizedFaces) {
        if (recognizedFace.isRecognized && recognizedFace.match != null) {
          final userId = recognizedFace.recognizedUserId!;
          final similarity = recognizedFace.match!.similarity;
          
          print('Recognized: ${recognizedFace.recognizedUserName}');
          print('Similarity: ${(similarity * 100).toStringAsFixed(1)}%');
          
          attendance[userId] = true; // Mark as present
        } else {
          print('Unknown face detected');
        }
      }

      return attendance;
    } catch (e) {
      print('Recognition failed: $e');
      return {};
    }
  }

  /// Example: Register multiple faces for better accuracy
  Future<void> registerMultipleFaces({
    required String studentId,
    required String studentName,
    int count = 3,
  }) async {
    print('Registering $count faces for $studentName...');

    for (int i = 0; i < count; i++) {
      print('Registering face ${i + 1}/$count');
      
      try {
        await registerStudentFace(
          studentId: studentId,
          studentName: studentName,
        );
      } catch (e) {
        print('Failed to register face ${i + 1}: $e');
      }
    }

    // Get all registered faces for this user
    final faces = await _faceRecognition.getUserFaces(studentId);
    print('Total faces registered: ${faces.length}');
  }

  /// Example: Get statistics
  Future<void> printStatistics() async {
    final stats = await _faceRecognition.getStatistics();
    print('Face Recognition Statistics:');
    print('Total faces: ${stats['totalFaces']}');
    print('Total users: ${stats['totalUsers']}');
    print('Threshold: ${stats['threshold']}');
    print('Model loaded: ${stats['isModelLoaded']}');
  }

  /// Dispose resources
  void dispose() {
    _faceRecognition.dispose();
  }
}

/// Example: Complete attendance marking flow
Future<void> exampleAttendanceFlow() async {
  final example = FaceRecognitionExample();
  
  // Initialize
  await example.initialize();

  // Register students (one-time setup)
  await example.registerMultipleFaces(
    studentId: 'student-1',
    studentName: 'John Doe',
    count: 3, // Register 3 faces for better accuracy
  );

  // Mark attendance
  final attendance = await example.markAttendanceFromPhoto();
  
  // Process attendance results
  attendance.forEach((userId, isPresent) {
    print('Student $userId: ${isPresent ? "Present" : "Absent"}');
    // Update attendance in database
  });

  // Print statistics
  await example.printStatistics();

  // Cleanup
  example.dispose();
}

