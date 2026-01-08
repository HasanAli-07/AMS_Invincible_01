# 🎯 Face Recognition Setup Guide

This guide will help you set up face recognition using Google ML Kit and TensorFlow Lite embeddings.

## 📋 Overview

The face recognition system uses:
- **Google ML Kit**: For face detection in images
- **TensorFlow Lite**: For generating face embeddings (128-dimensional vectors)
- **Cosine Similarity**: For matching faces against stored embeddings

## ✅ Current Status

The face recognition infrastructure is **fully implemented** and integrated with the attendance system. However, you need to add a TensorFlow Lite model file for production use.

## 🔧 Setup Steps

### Step 1: Download a Face Recognition TFLite Model

You need a lightweight face recognition model that outputs embeddings. Recommended models:

#### Option A: MobileFaceNet (Recommended)
- **Size**: ~4-5 MB
- **Input**: 112x112 RGB image
- **Output**: 128-dimensional embedding
- **Download**: Search for "MobileFaceNet TFLite" or use models from:
  - [TensorFlow Hub](https://tfhub.dev/)
  - [Model Zoo](https://github.com/tensorflow/models)

#### Option B: FaceNet (Larger but more accurate)
- **Size**: ~10-15 MB
- **Input**: 160x160 RGB image
- **Output**: 128 or 512-dimensional embedding

#### Option C: Use Pre-trained Model
You can find pre-trained models at:
- [Face Recognition Models](https://github.com/timesler/facenet-pytorch)
- [TensorFlow Lite Models](https://www.tensorflow.org/lite/models)

### Step 2: Add Model to Project

1. Create the models directory:
   ```bash
   mkdir -p attendance_system/assets/models
   ```

2. Place your TFLite model file:
   ```
   attendance_system/assets/models/face_recognition.tflite
   ```

3. Update `pubspec.yaml` to include the model:
   ```yaml
   flutter:
     assets:
       - assets/models/face_recognition.tflite
   ```

   **Note**: The asset path is already commented in `pubspec.yaml`. Just uncomment it after adding the model.

### Step 3: Configure Model Parameters (if needed)

If your model has different input/output sizes, update `face_embedding_service.dart`:

```dart
// In face_embedding_service.dart
static const int _inputSize = 112; // Change if your model uses 160x160
static const int _embeddingSize = 128; // Change if your model outputs 512 dimensions
```

### Step 4: Test the Setup

1. Run the app:
   ```bash
   flutter run
   ```

2. Navigate to the Face Recognition Demo screen (if available)

3. Try registering a face:
   - The system will detect faces using ML Kit
   - Generate embeddings using TFLite
   - Store embeddings in Firestore

4. Try recognizing faces:
   - Capture a photo with multiple faces
   - The system will match against stored embeddings

## 🎯 How It Works

### 1. Face Detection (ML Kit)
- Detects all faces in an image
- Provides bounding boxes and quality metrics
- Filters out low-quality faces (eyes closed, too rotated)

### 2. Face Cropping
- Crops each detected face with padding
- Resizes to model input size (112x112)
- Converts to RGB format

### 3. Embedding Generation (TFLite)
- Preprocesses image (normalize pixel values)
- Runs inference through TFLite model
- Extracts embedding vector (128 dimensions)
- Normalizes embedding (L2 normalization)

### 4. Face Matching
- Compares query embedding with stored embeddings
- Uses cosine similarity (dot product for normalized vectors)
- Returns matches above threshold (default: 0.70)

## 📱 Integration with Attendance System

The face recognition is integrated with the teacher dashboard:

1. **Capture Photo**: Teacher captures class photo
2. **Face Detection**: System detects all faces
3. **Recognition**: Matches faces to enrolled students
4. **Confirmation**: Shows recognized students with confidence scores
5. **Attendance Marking**: Teacher confirms or edits attendance

### Usage in Code

```dart
// Process attendance photo
final service = AttendanceFaceRecognitionService();
final result = await service.processAttendancePhoto(
  imageBytes: imageBytes,
);

// Access results
for (final student in result.recognizedStudents) {
  if (student.isRecognized) {
    print('Recognized: ${student.studentName} (${student.confidence})');
  }
}
```

## ⚙️ Configuration

### Similarity Threshold

Default: **0.70** (70% similarity)

Adjust in `face_matcher.dart` or when creating the matcher:

```dart
final faceMatcher = FaceMatcher(threshold: 0.75); // 75% threshold
```

- **0.60**: More lenient (more false positives)
- **0.70**: Balanced (recommended)
- **0.80**: Strict (fewer false positives, more false negatives)

### Model Configuration

Edit `face_embedding_service.dart`:

```dart
static const int _inputSize = 112; // Model input size
static const int _embeddingSize = 128; // Embedding dimension
static const String _modelPath = 'assets/models/face_recognition.tflite';
```

## 🚨 Fallback Mode

If no TFLite model is provided, the system uses **mock embeddings** for testing:
- Generates deterministic embeddings based on image hash
- **NOT suitable for production**
- Allows testing the UI and flow without a real model

You'll see this warning in logs:
```
Warning: TFLite model not found. Using fallback embedding generator.
```

## 📊 Storage

Face embeddings are stored in **Firestore**:
- Collection: `faces`
- Fields:
  - `userId`: Student/User ID
  - `userName`: Student name
  - `embedding`: Array of doubles (128 values)
  - `createdAt`: Timestamp
  - `imagePath`: Optional image path

## 🔍 Troubleshooting

### Model Not Loading
- Check file path: `assets/models/face_recognition.tflite`
- Verify `pubspec.yaml` includes the asset
- Run `flutter pub get` after adding asset
- Check model file size (should be 4-15 MB)

### Low Recognition Accuracy
- Ensure good lighting in photos
- Use higher quality images
- Adjust similarity threshold
- Train with multiple images per person
- Check model input/output sizes match configuration

### Face Detection Fails
- Check camera permissions in AndroidManifest.xml
- Ensure ML Kit is properly initialized
- Check image quality and lighting
- Verify face is clearly visible (not too small, not too rotated)

### Performance Issues
- Use smaller model (MobileFaceNet)
- Reduce image quality slightly
- Process images in background
- Cache embeddings locally

## 📚 Additional Resources

- [Google ML Kit Face Detection](https://developers.google.com/ml-kit/vision/face-detection)
- [TensorFlow Lite](https://www.tensorflow.org/lite)
- [Face Recognition Best Practices](https://github.com/timesler/facenet-pytorch)

## ✅ Checklist

- [ ] Download TFLite face recognition model
- [ ] Place model in `assets/models/face_recognition.tflite`
- [ ] Uncomment model asset in `pubspec.yaml`
- [ ] Run `flutter pub get`
- [ ] Test face registration
- [ ] Test face recognition
- [ ] Adjust similarity threshold if needed
- [ ] Verify Firestore storage is working

## 🎉 Success!

Once the model is added, face recognition will work automatically:
- ✅ Face detection using ML Kit
- ✅ Embedding generation using TFLite
- ✅ Face matching using cosine similarity
- ✅ Integration with attendance system
- ✅ Storage in Firestore

The system is ready for production use!
