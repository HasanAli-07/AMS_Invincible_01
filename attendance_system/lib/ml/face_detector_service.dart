/// Face Detection Service using Google ML Kit
/// 
/// This service handles:
/// - Face detection in images
/// - Multi-face detection
/// - Face quality assessment
/// - Bounding box extraction

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Size;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'
    show
        FaceDetector,
        FaceDetectorOptions,
        InputImage,
        InputImageMetadata,
        InputImageRotation,
        InputImageFormat;
import 'package:image/image.dart' as img;
import 'face_models.dart';

class FaceDetectorService {
  late final FaceDetector _faceDetector;

  FaceDetectorService() {
    // Configure ML Kit Face Detector
    final options = FaceDetectorOptions(
      enableClassification: true, // Enable eye open, smiling probabilities
      enableLandmarks: false, // We don't need landmarks for recognition
      enableTracking: false, // Not needed for static images
      minFaceSize: 0.15, // Minimum face size (15% of image)
    );
    
    _faceDetector = FaceDetector(options: options);
  }

  /// Detect all faces in an image file
  Future<List<DetectedFace>> detectFacesFromFile(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Image file not found: $imagePath');
    }
    
    final inputImage = InputImage.fromFilePath(imagePath);
    return await _detectFaces(inputImage);
  }

  /// Detect all faces in a Uint8List image
  Future<List<DetectedFace>> detectFacesFromBytes(
    Uint8List imageBytes,
    int width,
    int height,
    InputImageRotation rotation,
  ) async {
    final inputImage = InputImage.fromBytes(
      bytes: imageBytes,
      metadata: InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21, // Common camera format
        bytesPerRow: width,
      ),
    );
    
    return await _detectFaces(inputImage);
  }

  /// Detect all faces in an InputImage
  Future<List<DetectedFace>> _detectFaces(InputImage inputImage) async {
    try {
      final faces = await _faceDetector.processImage(inputImage);
      
      return faces.map((face) {
        final boundingBox = face.boundingBox;
        
        return DetectedFace(
          boundingBox: Rect(
            left: boundingBox.left.toDouble(),
            top: boundingBox.top.toDouble(),
            right: boundingBox.right.toDouble(),
            bottom: boundingBox.bottom.toDouble(),
          ),
          leftEyeOpenProbability: face.leftEyeOpenProbability,
          rightEyeOpenProbability: face.rightEyeOpenProbability,
          smilingProbability: face.smilingProbability,
          headEulerAngleY: face.headEulerAngleY,
          headEulerAngleZ: face.headEulerAngleZ,
        );
      }).toList();
    } catch (e) {
      throw Exception('Face detection failed: $e');
    }
  }

  /// Crop face from image using bounding box
  /// Returns cropped and normalized face image (112x112 or 160x160)
  Future<Uint8List> cropFace(
    Uint8List imageBytes,
    DetectedFace face,
    int targetSize,
  ) async {
    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate crop coordinates
      final bbox = face.boundingBox;
      final x = bbox.left.toInt().clamp(0, image.width);
      final y = bbox.top.toInt().clamp(0, image.height);
      final w = bbox.width.toInt().clamp(1, image.width - x);
      final h = bbox.height.toInt().clamp(1, image.height - y);

      // Crop face with some padding (10% padding)
      final padding = (w * 0.1).toInt();
      final cropX = (x - padding).clamp(0, image.width);
      final cropY = (y - padding).clamp(0, image.height);
      final cropW = (w + padding * 2).clamp(1, image.width - cropX);
      final cropH = (h + padding * 2).clamp(1, image.height - cropY);

      // Crop and resize to target size
      final cropped = img.copyCrop(
        image,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );

      // Resize to target size (square)
      final resized = img.copyResize(
        cropped,
        width: targetSize,
        height: targetSize,
        interpolation: img.Interpolation.cubic,
      );

      // Convert to RGB format (remove alpha channel if present)
      img.Image rgb = resized;
      if (resized.hasAlpha) {
        // Create new RGB image without alpha
        rgb = img.Image(width: resized.width, height: resized.height);
        for (int y = 0; y < resized.height; y++) {
          for (int x = 0; x < resized.width; x++) {
            final pixel = resized.getPixel(x, y);
            rgb.setPixel(x, y, img.ColorRgb8(
              pixel.r.toInt(),
              pixel.g.toInt(),
              pixel.b.toInt(),
            ));
          }
        }
      }

      // Encode to bytes
      return Uint8List.fromList(img.encodeJpg(rgb, quality: 95));
    } catch (e) {
      throw Exception('Face cropping failed: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _faceDetector.close();
  }
}

