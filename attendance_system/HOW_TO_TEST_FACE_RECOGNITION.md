# How to Test Face Recognition System

## 🚀 Quick Start Guide

### Step 1: Run the App

```bash
cd attendance_system
flutter run
```

### Step 2: Login

Use any of these credentials:
- **Principal**: `principal@school.com` / `principal123`
- **Teacher**: `teacher@school.com` / `teacher123`
- **Student**: `student@school.com` / `student123`

### Step 3: Access Face Recognition Demo

**Option A: From Principal Dashboard**
1. Login as Principal
2. Click on "Upload Students" quick action
3. Click "Test Face Recognition" button in the dialog
4. You'll be taken to the Face Recognition Demo screen

**Option B: Direct Navigation**
- The route is: `/face-recognition-demo`
- You can add a button anywhere to navigate to this screen

## 📱 Using the Face Recognition Demo Screen

### 1. System Status
- Shows initialization status
- Displays current system state
- Shows error messages if any

### 2. Statistics
- **Total Faces**: Number of registered faces
- **Total Users**: Number of unique users
- **Threshold**: Similarity threshold (default: 0.70)
- **Model Status**: Whether TFLite model is loaded

### 3. Register Face (Enrollment)

**Steps:**
1. Click "Register Face (Enrollment)" button
2. Take a photo or pick from gallery
3. Enter User ID (e.g., `student-123`)
4. Enter User Name (e.g., `John Doe`)
5. Wait for registration to complete

**Tips:**
- Register 3-5 faces per person for better accuracy
- Ensure good lighting
- Face should be clearly visible
- Avoid extreme head rotation

### 4. Recognize Faces (Attendance)

**Steps:**
1. Click "Recognize Faces (Attendance)" button
2. Take a photo (can contain multiple faces)
3. Wait for recognition to complete
4. View results:
   - Total faces detected
   - Recognized faces with similarity scores
   - Unknown faces

**Results Format:**
```
Recognition Complete!

Total Faces: 3
Recognized: 2
Unknown: 1

Recognized:
John Doe (87.5%)
Jane Smith (92.3%)
```

## 🧪 Testing Scenarios

### Test 1: Single Face Registration
1. Register one face for a person
2. Take another photo of the same person
3. Check if it recognizes correctly
4. Note the similarity score

### Test 2: Multiple Faces Registration
1. Register 3-5 faces of the same person (different angles)
2. Take a new photo
3. Check if recognition is more accurate
4. Compare similarity scores

### Test 3: Group Photo Recognition
1. Register faces for multiple people
2. Take a group photo
3. Check if all registered faces are recognized
4. Verify unknown faces are marked correctly

### Test 4: Different People
1. Register face for Person A
2. Take photo of Person B
3. Verify Person B is NOT recognized as Person A
4. Check similarity score (should be below threshold)

### Test 5: Quality Assessment
1. Take photo with poor lighting
2. Take photo with head rotated
3. Take photo with eyes closed
4. Check if system handles these cases

## 📊 Understanding Results

### Similarity Scores
- **0.70 - 1.0**: Strong match (recognized)
- **0.50 - 0.70**: Weak match (may be recognized if threshold is lower)
- **0.0 - 0.50**: No match (different person)

### Threshold Tuning
- **Lower threshold (0.60)**: More lenient, more false positives
- **Default (0.70)**: Balanced
- **Higher threshold (0.80)**: Stricter, fewer false positives

## ⚠️ Important Notes

### Without TFLite Model
- System uses **fallback/mock embeddings** for testing
- This is **NOT real face recognition**
- Similarity scores are based on image hash, not actual face features
- **For real recognition, add a TFLite model**

### With TFLite Model
1. Download MobileFaceNet or similar model
2. Place in `assets/models/face_recognition.tflite`
3. Update `pubspec.yaml` (already done)
4. Restart app
5. System will use real face embeddings

## 🔍 Debugging

### Check Statistics
- View statistics card on demo screen
- Verify model is loaded
- Check face/user counts

### Check Recent Results
- View recent registration/recognition results
- Check for error messages
- Verify similarity scores

### Common Issues

**Issue: "No face detected"**
- Ensure face is clearly visible
- Check lighting
- Try different angle

**Issue: "Face quality not acceptable"**
- Head rotation too extreme
- Eyes closed
- Face too small in image

**Issue: "Model not loaded"**
- Add TFLite model file
- Check asset path in pubspec.yaml
- Restart app

**Issue: Low similarity scores**
- Register more faces per person
- Use better quality images
- Adjust threshold if needed

## 📝 Example Test Flow

1. **Initial Setup**
   - Login as Principal
   - Navigate to Face Recognition Demo
   - Check system status (should be ready)

2. **Register Test Users**
   - Register: `student-1` / `John Doe` (3 faces)
   - Register: `student-2` / `Jane Smith` (3 faces)
   - Register: `student-3` / `Bob Wilson` (3 faces)

3. **Test Recognition**
   - Take photo with John → Should recognize
   - Take photo with Jane → Should recognize
   - Take photo with unknown person → Should mark as unknown
   - Take group photo → Should recognize all registered faces

4. **Verify Results**
   - Check similarity scores (should be > 0.70)
   - Verify correct user names
   - Check statistics updated correctly

## 🎯 Success Criteria

✅ System initializes without errors  
✅ Faces can be registered successfully  
✅ Registered faces are recognized correctly  
✅ Similarity scores are reasonable (> 0.70 for same person)  
✅ Different people are not matched incorrectly  
✅ Multiple faces in one image are handled  
✅ Statistics update correctly  

## 📚 Next Steps

1. Add real TFLite model for production use
2. Integrate with attendance marking flow
3. Add face enrollment UI in student management
4. Add camera preview for real-time detection
5. Add persistence (SQLite/Hive) for embeddings

---

**Ready to test!** Run the app and navigate to the Face Recognition Demo screen.

