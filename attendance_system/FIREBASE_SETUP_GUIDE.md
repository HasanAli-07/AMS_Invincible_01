# Firebase Integration Setup Guide

## ✅ Implementation Complete

Firebase integration has been implemented using **ONLY FREE tier features**:
- ✅ Firebase Authentication (Email/Password)
- ✅ Cloud Firestore (Database)
- ✅ Firebase Storage (Light use)

## 📋 Setup Steps

### Step 1: Create Firebase Project

1. Go to https://console.firebase.google.com
2. Click "Add project"
3. Enter project name (e.g., "attendance-system")
4. Enable Google Analytics (optional, FREE)
5. Create project

### Step 2: Add Android App

1. In Firebase Console, click "Add app" > Android
2. Enter package name: `com.example.attendance_system`
   (Check `android/app/build.gradle` for actual package name)
3. Register app
4. Download `google-services.json`
5. Place file in: `android/app/google-services.json`

### Step 3: Configure Android Build

1. Open `android/build.gradle` (project level)
2. Add to `buildscript.dependencies`:
```gradle
classpath 'com.google.gms:google-services:4.4.2'
```

3. Open `android/app/build.gradle`
4. Add at the top:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### Step 4: Generate Firebase Options (Recommended)

**Option A: Using FlutterFire CLI (Recommended)**

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

This will automatically:
- Detect your Firebase projects
- Generate `firebase_options.dart`
- Update `firebase_config.dart`

**Option B: Manual Configuration**

1. Get values from Firebase Console > Project Settings
2. Update `lib/firebase/firebase_config.dart`:
   - Replace `YOUR_API_KEY`
   - Replace `YOUR_APP_ID`
   - Replace `YOUR_SENDER_ID`
   - Replace `YOUR_PROJECT_ID`
   - Replace `YOUR_STORAGE_BUCKET`

### Step 5: Enable Firebase Services

In Firebase Console:

1. **Authentication**
   - Go to Authentication > Sign-in method
   - Enable "Email/Password"
   - Save

2. **Firestore Database**
   - Go to Firestore Database
   - Create database
   - Start in **test mode** (we'll add security rules)
   - Choose location (closest to your users)

3. **Storage** (Optional)
   - Go to Storage
   - Get started
   - Start in **test mode**
   - Choose location

### Step 6: Deploy Security Rules

1. **Firestore Rules**
   - Go to Firestore Database > Rules
   - Copy contents of `firestore.rules`
   - Paste and Publish

2. **Storage Rules**
   - Go to Storage > Rules
   - Copy contents of `storage.rules`
   - Paste and Publish

### Step 7: Install Dependencies

```bash
cd attendance_system
flutter pub get
```

### Step 8: Test Firebase Connection

Run the app:
```bash
flutter run
```

Check logs for:
- "Firebase initialized successfully" ✅
- Any Firebase errors

## 📁 Files Created

### Services
- `lib/firebase/firebase_config.dart` - Firebase initialization
- `lib/firebase/services/firebase_auth_service.dart` - Auth operations
- `lib/firebase/services/firestore_user_service.dart` - User profiles
- `lib/firebase/services/firestore_attendance_service.dart` - Attendance records
- `lib/firebase/services/firestore_student_service.dart` - Student data
- `lib/firebase/services/firestore_teacher_service.dart` - Teacher data
- `lib/firebase/services/firestore_subject_service.dart` - Subject data
- `lib/firebase/services/firestore_class_service.dart` - Class data
- `lib/firebase/services/firebase_storage_service.dart` - File storage
- `lib/firebase/services/firebase_integrated_auth_service.dart` - Combined auth

### Security Rules
- `firestore.rules` - Firestore security rules
- `storage.rules` - Storage security rules

## 🗄️ Database Structure

### Collections

**users**
```
userId (doc)
├── name: string
├── email: string
├── role: 'student' | 'teacher' | 'principal' | 'admin'
├── academicUnitId: string?
├── createdAt: Timestamp
└── updatedAt: Timestamp
```

**students**
```
studentId (doc)
├── name: string
├── email: string
├── rollNumber: string
├── classId: string
├── enrollmentDate: Timestamp
├── faceEmbeddings: List<List<double>>
├── createdAt: Timestamp
└── updatedAt: Timestamp
```

**teachers**
```
teacherId (doc)
├── name: string
├── email: string
├── department: string
├── subjectIds: string[]
├── classIds: string[]
├── joinDate: Timestamp
├── createdAt: Timestamp
└── updatedAt: Timestamp
```

**attendance**
```
attendanceId (doc)
├── date: Timestamp
├── subjectId: string
├── classId: string
├── teacherId: string
├── presentStudentIds: string[]
├── absentStudentIds: string[]
├── lateStudentIds: string[]
├── confirmedByTeacher: boolean
├── createdAt: Timestamp
└── updatedAt: Timestamp
```

**subjects**
```
subjectId (doc)
├── name: string
├── code: string
├── department: string
├── credits: number
├── description: string?
├── createdAt: Timestamp
└── updatedAt: Timestamp
```

**academic_units**
```
classId (doc)
├── name: string
├── department: string
├── academicYear: string
├── totalStudents: number
├── classTeacherId: string?
├── createdAt: Timestamp
└── updatedAt: Timestamp
```

## 🔐 Security Rules Summary

### Firestore Rules
- ✅ Only authenticated users can access data
- ✅ Users can read/update their own profile
- ✅ Students can read their own attendance
- ✅ Teachers can create/update attendance
- ✅ Principals have broader access
- ✅ Admins have full access

### Storage Rules
- ✅ File size limits (5MB enrollment, 2MB profiles)
- ✅ Only image files allowed
- ✅ Role-based access control

## 💰 FREE Tier Limits

### Authentication
- ✅ Unlimited users
- ✅ Email/Password auth
- ✅ Password reset

### Firestore
- ✅ 1 GB storage
- ✅ 50K reads/day
- ✅ 20K writes/day
- ✅ 20K deletes/day

### Storage
- ✅ 5 GB storage
- ✅ 1 GB downloads/day

**Note**: These limits are generous for small-medium institutions. Monitor usage in Firebase Console.

## 🚀 Usage Examples

### Sign Up
```dart
final authService = FirebaseIntegratedAuthService(...);
final user = await authService.signUp(
  email: 'student@school.com',
  password: 'password123',
  name: 'John Doe',
  role: UserRole.student,
  academicUnitId: 'class-10a',
);
```

### Sign In
```dart
final user = await authService.signIn(
  email: 'student@school.com',
  password: 'password123',
);
```

### Create Attendance
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

## ⚠️ Important Notes

1. **Before Production**:
   - Update `firebase_config.dart` with real values
   - Deploy security rules
   - Test all operations
   - Monitor Firebase Console for usage

2. **Security**:
   - Never commit `google-services.json` to public repos
   - Use environment variables for sensitive config
   - Regularly review security rules

3. **Performance**:
   - Use Firestore indexes for complex queries
   - Implement pagination for large datasets
   - Cache frequently accessed data

4. **Cost Management**:
   - Monitor usage in Firebase Console
   - Set up billing alerts
   - Optimize queries to reduce reads

## 🔄 Migration from Local Storage

The app currently uses in-memory repositories. To migrate to Firebase:

1. Keep existing repositories as fallback
2. Create Firebase-backed repositories
3. Update AppState to use Firebase repositories
4. Migrate existing data (if any)

## 📚 Next Steps

1. Complete Firebase setup (Steps 1-8)
2. Test authentication flow
3. Test Firestore operations
4. Integrate with existing UI
5. Deploy security rules
6. Monitor usage

---

**Ready to use!** Follow the setup steps above to connect Firebase to your app.

