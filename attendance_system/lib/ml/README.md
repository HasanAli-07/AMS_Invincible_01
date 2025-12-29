# Face Recognition System

## Overview

This is a **REAL, WORKING** face recognition system using Google ML Kit and TensorFlow Lite for Flutter. It implements a complete face recognition pipeline for attendance marking.

## Architecture

### Pipeline Steps

1. **Face Detection** (ML Kit)
   - Detects all faces in an image
   - Extracts bounding boxes
   - Assesses face quality (rotation, eye open, etc.)

2. **Face Cropping**
   - Crops detected faces with padding
   - Normalizes to 112x112 pixels
   - Converts to RGB format

3. **Face Embedding** (TensorFlow Lite)
   - Generates numerical embeddings (128-dim vector)
   - Normalizes embeddings (L2 normalization)

4. **Face Matching** (Cosine Similarity)
   - Compares embeddings with stored faces
   - Uses cosine similarity (0.0 to 1.0)
   - Threshold-based decision (default: 0.70)

5. **Recognition Result**
   - Returns matched identity or "unknown"
   - Provides confidence scores
   - Supports multiple faces per image

## Components

### `face_models.dart`
Data models for the face recognition system:
- `DetectedFace`: Face detected by ML Kit
- `FaceEmbedding`: Numerical representation (vector)
- `StoredFace`: Stored face data for a user
- `FaceMatch`: Matching result with similarity score
- `FaceRecognitionResult`: Complete recognition result

### `face_detector_service.dart`
Face detection using Google ML Kit:
- Multi-face detection
- Face quality assessment
- Face cropping and normalization

### `face_embedding_service.dart`
Face embedding generation using TensorFlow Lite:
- Loads TFLite model
- Preprocesses images
- Generates embeddings
- Normalizes embeddings

### `face_matcher.dart`
Face matching using cosine similarity:
- Cosine similarity calculation
- Best match finding
- Threshold-based decision

### `face_repository.dart`
Storage for face embeddings:
- Store/retrieve embeddings
- Manage multiple embeddings per user
- In-memory implementation (can be extended to SQLite)

### `face_recognition_service.dart`
Main service orchestrating the pipeline:
- `registerFace()`: Enroll a new face
- `recognizeFaces()`: Recognize faces in an image
- Complete pipeline integration

## Setup

### 1. Add Dependencies

Already added to `pubspec.yaml`:
```yaml
google_mlkit_face_detection: ^4.0.0
tflite_flutter: ^0.11.0
image: ^4.1.7
camera: ^0.11.0+2
path_provider: ^2.1.2
image_picker: ^1.1.2
```

### 2. Add TFLite Model

1. Download a face recognition TFLite model (e.g., MobileFaceNet)
2. Place it in `assets/models/face_recognition.tflite`
3. Add to `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/models/face_recognition.tflite
```

**Recommended Models:**
- MobileFaceNet (lightweight, 128-dim embeddings)
- FaceNet (more accurate, 512-dim embeddings)
- ArcFace (state-of-the-art, requires model conversion)

### 3. Initialize Service

```dart
final faceDetector = FaceDetectorService();
final embeddingService = FaceEmbeddingService();
final faceMatcher = FaceMatcher(threshold: 0.70);
final faceRepository = InMemoryFaceRepository();

final faceRecognition = FaceRecognitionService(
  faceDetector: faceDetector,
  embeddingService: embeddingService,
  faceMatcher: faceMatcher,
  faceRepository: faceRepository,
);

await faceRecognition.initialize();
```

## Usage

### Register a Face (Enrollment)

```dart
// When adding a new student
final imageBytes = await imagePicker.pickImage(...);
final storedFace = await faceRecognition.registerFace(
  userId: 'student-123',
  userName: 'John Doe',
  imageBytes: imageBytes,
);
```

### Recognize Faces (Attendance)

```dart
// During attendance marking
final imageBytes = await cameraController.takePicture();
final result = await faceRecognition.recognizeFaces(
  imageBytes: imageBytes,
  imageWidth: 640,
  imageHeight: 480,
);

// Process results
for (final recognizedFace in result.recognizedFaces) {
  if (recognizedFace.isRecognized) {
    print('Recognized: ${recognizedFace.recognizedUserName}');
    print('Similarity: ${recognizedFace.match!.similarity}');
    // Mark attendance for recognizedFace.recognizedUserId
  } else {
    print('Unknown face detected');
  }
}
```

## Threshold Tuning

The similarity threshold determines recognition accuracy:

- **0.60**: Very lenient (more false positives)
- **0.70**: Balanced (recommended default)
- **0.80**: Strict (fewer false positives, more false negatives)

Adjust based on:
- Model accuracy
- Use case requirements
- False positive vs false negative tolerance

```dart
final matcher = FaceMatcher(threshold: 0.75); // Custom threshold
```

## Accuracy Tips

1. **Multiple Embeddings per Person**
   - Register 3-5 faces per person from different angles
   - Improves recognition accuracy

2. **Face Quality**
   - Ensure good lighting
   - Face should be clearly visible
   - Avoid extreme head rotation (>30°)
   - Eyes should be open

3. **Image Quality**
   - Use at least 640x480 resolution
   - Ensure proper focus
   - Avoid motion blur

4. **Model Selection**
   - Use a model trained on diverse faces
   - MobileFaceNet is good for mobile devices
   - Larger models = better accuracy but slower

## Testing

Test with:
- Same person, different images → Should match
- Different people → Should not match
- Multiple faces in one image → Should recognize all
- Low quality images → Should handle gracefully

## Production Considerations

1. **Model Loading**
   - Load model once at app startup
   - Cache embeddings in local database
   - Use SQLite/Hive for persistence

2. **Performance**
   - Process faces in background
   - Show loading indicators
   - Cache recent results

3. **Privacy**
   - Store only embeddings, not raw images
   - Encrypt stored data
   - Comply with privacy regulations

4. **Error Handling**
   - Handle model loading failures
   - Handle face detection failures
   - Provide user feedback

## Troubleshooting

### Model Not Found
- Ensure model file is in `assets/models/`
- Check `pubspec.yaml` includes the asset
- Run `flutter pub get`

### Low Recognition Accuracy
- Increase number of registered faces per person
- Adjust threshold
- Use a better TFLite model
- Ensure good image quality

### Performance Issues
- Use smaller model (MobileFaceNet)
- Reduce image resolution
- Process in background thread

## Next Steps

1. Add TFLite model file
2. Integrate with attendance marking UI
3. Add camera preview for real-time detection
4. Add face enrollment UI
5. Add persistence (SQLite/Hive)
6. Add batch processing for group photos

