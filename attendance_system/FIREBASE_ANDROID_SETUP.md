# Firebase Android Setup - Simple Guide

## ✅ Step 3: Android Configuration (DONE!)

I've already configured the Android files for you! Here's what was done:

### Files Modified:

1. **`android/settings.gradle.kts`**
   - Added Google Services plugin

2. **`android/app/build.gradle.kts`**
   - Added Google Services plugin application

3. **`android/app/google-services.json`**
   - ✅ Already exists! (You must have downloaded it)

## 🎯 What You Need to Do Now:

### Step 1: Verify google-services.json

Check if `android/app/google-services.json` exists and has content.

If it's empty or missing:
1. Go to Firebase Console
2. Project Settings > Your apps > Android app
3. Download `google-services.json`
4. Replace the file in `android/app/`

### Step 2: Get Firebase Config Values

You need to get these values from `google-services.json`:

1. Open `android/app/google-services.json`
2. Find these values:
   - `api_key` → current_key → `api_key`
   - `mobilesdk_app_id` → `app_id`
   - `project_number` → `messaging_sender_id`
   - `project_id` → `project_id`
   - `storage_bucket` → `storage_bucket`

### Step 3: Update firebase_config.dart

Open `lib/firebase/firebase_config.dart` and replace:

```dart
return const FirebaseOptions(
  apiKey: 'YOUR_API_KEY',           // From google-services.json
  appId: 'YOUR_APP_ID',             // From google-services.json
  messagingSenderId: 'YOUR_SENDER_ID', // From google-services.json
  projectId: 'YOUR_PROJECT_ID',     // From google-services.json
  storageBucket: 'YOUR_STORAGE_BUCKET', // From google-services.json
);
```

**OR** (Recommended) Use FlutterFire CLI:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase (this will auto-update firebase_config.dart)
flutterfire configure
```

### Step 4: Test

```bash
flutter pub get
flutter run
```

Check logs for: "Firebase initialized successfully"

## 📝 Quick Checklist

- [x] Android build files configured (DONE!)
- [ ] `google-services.json` has correct content
- [ ] Firebase config values updated (or run `flutterfire configure`)
- [ ] Run `flutter pub get`
- [ ] Test app runs without errors

## 🔍 How to Check google-services.json

Open `android/app/google-services.json` and look for:

```json
{
  "project_info": {
    "project_number": "123456789",
    "project_id": "your-project-id",
    "storage_bucket": "your-project.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789:android:abc123",
        "android_client_info": {
          "package_name": "com.example.attendance_system"
        }
      },
      "api_key": [
        {
          "current_key": "AIzaSy..."
        }
      ]
    }
  ]
}
```

If you see this structure, you're good! ✅

## ⚠️ Common Issues

**Issue: "Plugin not found"**
- Solution: Run `flutter pub get` first

**Issue: "google-services.json not found"**
- Solution: Download from Firebase Console and place in `android/app/`

**Issue: "Package name mismatch"**
- Solution: Check package name in `android/app/build.gradle.kts` matches Firebase project

---

**Android configuration is DONE!** Just update Firebase config values and you're ready to go! 🚀

