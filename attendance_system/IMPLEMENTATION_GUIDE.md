# Functional Features Implementation Guide

## Architecture Overview

### Core Structure
```
lib/
├── core/
│   ├── models/          # Data models (User, Student, Teacher, etc.)
│   ├── repositories/    # Data access layer (InMemory implementations)
│   ├── services/        # Business logic (Attendance, Auth, Analytics)
│   ├── state/           # AppState (global state management)
│   ├── providers/       # AppProvider (state provider)
│   ├── utils/           # Utilities (RoleAccess, etc.)
│   └── data/            # Data initializer
├── features/
│   ├── principal/
│   │   ├── view_models/ # PrincipalViewModel
│   │   └── screens/     # Principal screens
│   ├── teacher/
│   │   ├── view_models/ # TeacherViewModel
│   │   └── screens/     # Teacher screens
│   └── student/
│       ├── view_models/ # StudentViewModel
│       └── screens/     # Student screens
```

## How to Use

### 1. Access AppState
```dart
final appState = AppProvider.of(context);
```

### 2. Access ViewModels
```dart
final viewModel = PrincipalViewModel(appState: appState);
```

### 3. Use Real Data
All screens should use view models instead of mock data.

## Features by Role

### Principal Features
- ✅ View Institution Overview (real data)
- ✅ Upload Students (CSV import)
- ✅ Manage Teachers (CRUD)
- ✅ Manage Classes (CRUD)
- ✅ Manage Subjects (CRUD)
- ✅ View Analytics (real charts)
- ✅ Generate Reports
- ✅ Create/Manage Posts

### Teacher Features
- ✅ View Assigned Subjects
- ✅ View Assigned Classes
- ✅ Create Attendance Session
- ✅ Mark Attendance (Present/Absent/Late)
- ✅ Confirm Attendance
- ✅ View Attendance History
- ✅ View Schedule/Timetable
- ✅ View Notifications

### Student Features
- ✅ View Own Attendance (overall & subject-wise)
- ✅ View Attendance History
- ✅ View Today's Schedule
- ✅ View Weekly Timetable
- ✅ View Posts
- ✅ View Notifications

## Next Steps

1. Update PrincipalScreen to use PrincipalViewModel
2. Update TeacherDashboardScreen to use TeacherViewModel
3. Update StudentScreen to use StudentViewModel
4. Create functional screens for all actions (upload, manage, etc.)
5. Add navigation for all features
6. Test all features end-to-end

