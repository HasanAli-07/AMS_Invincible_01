# How to Test Firebase Integration

## 🚀 Quick Start

### Step 1: Setup Firebase (One-time)

1. **Create Firebase Project**
   - Go to https://console.firebase.google.com
   - Click "Add project"
   - Enter project name
   - Create project

2. **Add Android App**
   - Click "Add app" > Android
   - Enter package name (check `android/app/build.gradle`)
   - Download `google-services.json`
   - Place in `android/app/google-services.json`

3. **Configure Android**
   - Add to `android/build.gradle`:
   ```gradle
   classpath 'com.google.gms:google-services:4.4.2'
   ```
   - Add to `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

4. **Generate Firebase Options**
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This updates `firebase_config.dart` automatically

5. **Enable Services in Firebase Console**
   - Authentication > Enable Email/Password
   - Firestore > Create database (test mode)
   - Storage > Get started (test mode)

### Step 2: Deploy Security Rules

1. **Firestore Rules**
   - Firebase Console > Firestore Database > Rules
   - Copy `firestore.rules` content
   - Paste and Publish

2. **Storage Rules**
   - Firebase Console > Storage > Rules
   - Copy `storage.rules` content
   - Paste and Publish

### Step 3: Install Dependencies

```bash
cd attendance_system
flutter pub get
```

### Step 4: Run App

```bash
flutter run
```

Check logs for:
- ✅ "Firebase initialized successfully"
- ❌ Any Firebase errors

## 🧪 Testing Firebase Features

### Test 1: Authentication

**Sign Up:**
```dart
// Use FirebaseIntegratedAuthService
final authService = FirebaseIntegratedAuthService(
  authService: FirebaseAuthService(),
  userService: FirestoreUserService(),
);

final user = await authService.signUp(
  email: 'test@school.com',
  password: 'test123',
  name: 'Test User',
  role: UserRole.student,
  academicUnitId: 'class-10a',
);
```

**Sign In:**
```dart
final user = await authService.signIn(
  email: 'test@school.com',
  password: 'test123',
);
```

**Check Firebase Console:**
- Authentication > Users → Should see new user
- Firestore > users → Should see user profile

### Test 2: Firestore Operations

**Create Student:**
```dart
final studentService = FirestoreStudentService();
final studentId = await studentService.createStudent(
  name: 'John Doe',
  email: 'john@school.com',
  rollNumber: '10A001',
  classId: 'class-10a',
);
```

**Create Attendance:**
```dart
final attendanceService = FirestoreAttendanceService();
final sessionId = await attendanceService.createAttendanceSession(
  date: DateTime.now(),
  subjectId: 'subj-1',
  classId: 'class-10a',
  teacherId: 'teacher-1',
  presentStudentIds: ['student-1', 'student-2'],
);
```

**Check Firestore Console:**
- Firestore Database → Should see collections
- Verify document structure matches schema

### Test 3: Storage (Optional)

**Upload Image:**
```dart
final storageService = FirebaseStorageService();
final url = await storageService.uploadStudentEnrollmentImage(
  studentId: 'student-1',
  imageBytes: imageBytes,
);
```

**Check Storage Console:**
- Storage → Should see uploaded files
- Verify file size limits

## 📊 Verify in Firebase Console

### Authentication
- Go to Authentication > Users
- Should see registered users
- Verify email verification status

### Firestore
- Go to Firestore Database
- Should see collections:
  - `users`
  - `students`
  - `teachers`
  - `attendance`
  - `subjects`
  - `academic_units`
- Click on documents to verify structure

### Storage
- Go to Storage
- Should see folders:
  - `students/`
  - `profiles/`
- Verify file sizes are within limits

## 🔍 Debugging

### Common Issues

**Issue: "Firebase not initialized"**
- Check `google-services.json` is in `android/app/`
- Verify `firebase_config.dart` has correct values
- Run `flutterfire configure` again

**Issue: "Permission denied"**
- Check security rules are deployed
- Verify user is authenticated
- Check user role matches rule requirements

**Issue: "Collection not found"**
- Collections are created automatically on first write
- Check Firestore Console after first operation

**Issue: "Quota exceeded"**
- Check Firebase Console > Usage
- FREE tier limits:
  - Firestore: 50K reads/day
  - Storage: 1 GB downloads/day

### Check Logs

```bash
flutter run --verbose
```

Look for:
- Firebase initialization messages
- Firestore operation logs
- Authentication errors

## ✅ Success Criteria

- ✅ Firebase initializes without errors
- ✅ Can sign up new users
- ✅ Can sign in existing users
- ✅ User profiles created in Firestore
- ✅ Can create/read Firestore documents
- ✅ Security rules working correctly
- ✅ Storage uploads working (if tested)

## 📝 Test Checklist

- [ ] Firebase project created
- [ ] `google-services.json` added
- [ ] Android build configured
- [ ] Firebase options generated
- [ ] Services enabled in Console
- [ ] Security rules deployed
- [ ] App runs without Firebase errors
- [ ] Can sign up user
- [ ] Can sign in user
- [ ] User profile in Firestore
- [ ] Can create attendance record
- [ ] Can read attendance records
- [ ] Storage upload works (optional)

## 🎯 Next Steps

1. Integrate Firebase auth with login screen
2. Replace in-memory repos with Firestore repos
3. Add real-time listeners for live updates
4. Implement offline persistence
5. Add error handling and retry logic

---

**Ready to test!** Follow the setup steps and verify each feature works correctly.

