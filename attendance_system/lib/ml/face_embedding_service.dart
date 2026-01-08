/// Face Embedding Service using TensorFlow Lite
/// 
/// This service handles:
/// - Loading TFLite model
/// - Generating face embeddings from cropped face images
/// - Normalizing embeddings for cosine similarity
/// 
/// IMPORTANT: You need to provide a TFLite model file
/// Recommended: MobileFaceNet or similar lightweight model
/// Model should output embeddings (128 or 512 dimensions)

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'face_models.dart';

class FaceEmbeddingService {
  Interpreter? _interpreter;
  bool _isInitialized = false;
  
  // Model configuration
  static const int _inputSize = 112; 
  int _embeddingSize = 192; // Updated to match the current model
  static const String _modelPath = 'assets/models/face_recognition.tflite';

  /// Initialize TFLite interpreter with face recognition model
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load model from assets
      final modelBytes = await rootBundle.load(_modelPath);
      final modelBuffer = modelBytes.buffer.asUint8List();

      // Create interpreter
      _interpreter = Interpreter.fromBuffer(modelBuffer);

      // Get input and output shapes
      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      debugPrint('Model loaded successfully');
      debugPrint('Input shape: $inputShape');
      debugPrint('Output shape: $outputShape');

      // Update embedding size dynamically if possible
      if (outputShape.length >= 2) {
        _embeddingSize = outputShape[1];
        debugPrint('Detected embedding size: $_embeddingSize');
      }

      _isInitialized = true;
    } catch (e) {
      // If model file doesn't exist, create a fallback
      debugPrint('Warning: TFLite model not found. Using fallback embedding generator.');
      debugPrint('To use real face recognition, add a TFLite model at: $_modelPath');
      _isInitialized = false;
    }
  }

  /// Generate face embedding from cropped face image
  /// 
  /// Input: Cropped face image (Uint8List, typically 112x112 RGB)
  /// Output: Normalized face embedding vector
  Future<FaceEmbedding> generateEmbedding(Uint8List faceImageBytes) async {
    if (!_isInitialized || _interpreter == null) {
      // Fallback: Generate a mock embedding for testing
      // In production, this should throw an error
      return _generateMockEmbedding(faceImageBytes);
    }

    try {
      // Preprocess image
      final input = await _preprocessImage(faceImageBytes);

      // Prepare output
      final output = [List<double>.filled(_embeddingSize, 0.0)];

      // Run inference
      _interpreter!.run(input, output);

      // Extract embedding
      final embedding = List<double>.from(output[0]);

      // Create and normalize embedding
      final faceEmbedding = FaceEmbedding(vector: embedding);
      return faceEmbedding.normalized();
    } catch (e) {
      throw Exception('Embedding generation failed: $e');
    }
  }

  /// Preprocess image for TFLite model
  /// 
  /// Steps:
  /// 1. Decode image
  /// 2. Resize to input size (112x112)
  /// 3. Convert to float32 array
  /// 4. Normalize pixel values to [-1, 1] or [0, 1] (model-dependent)
  Future<List<List<List<List<double>>>>> _preprocessImage(
    Uint8List imageBytes,
  ) async {
    // Decode image
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image for preprocessing');
    }

    // Resize to model input size
    final resized = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.cubic,
    );

    // Convert to RGB format (ensure 3 channels)
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

    // Create 4D tensor: [1, height, width, channels]
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (h) => List.generate(
          _inputSize,
          (w) => List.generate(3, (c) {
            final pixel = rgb.getPixel(w, h);
            int pixelValue;
            // Access color channels directly from pixel
            final color = pixel;
            switch (c) {
              case 0:
                pixelValue = color.r.toInt();
                break;
              case 1:
                pixelValue = color.g.toInt();
                break;
              case 2:
                pixelValue = color.b.toInt();
                break;
              default:
                pixelValue = 0;
            }
            
            // Normalize to [-1, 1] range (common for face recognition models)
            // Alternative: normalize to [0, 1] by dividing by 255.0
            return (pixelValue / 127.5) - 1.0;
          }),
        ),
      ),
    );

    return input;
  }

  /// Fallback: Generate mock embedding for testing
  /// 
  /// This creates a deterministic embedding based on image hash
  /// NOT suitable for production - only for testing without TFLite model
  FaceEmbedding _generateMockEmbedding(Uint8List imageBytes) {
    // Create a simple hash-based embedding
    // This is NOT real face recognition - just for testing
    final hash = _simpleHash(imageBytes);
    final embedding = List.generate(_embeddingSize, (i) {
      // Generate pseudo-random but deterministic values
      final seed = hash + i;
      return (seed % 2000 - 1000) / 1000.0; // Values between -1 and 1
    });

    final faceEmbedding = FaceEmbedding(vector: embedding);
    return faceEmbedding.normalized();
  }

  int _simpleHash(Uint8List bytes) {
    int hash = 0;
    for (int i = 0; i < bytes.length && i < 100; i++) {
      hash = ((hash << 5) - hash) + bytes[i];
      hash = hash & hash; // Convert to 32-bit integer
    }
    return hash.abs();
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}

