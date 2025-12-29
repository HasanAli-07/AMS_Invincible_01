## Firebase Database Schema & RBAC Overview

This document summarizes the **collections, fields, and RBAC behavior** for the connected Firebase project.

---

### 1. `users` (Core RBAC anchor)

- **Collection**: `users`
- **Document ID**: `auth.uid` (from Firebase Authentication)

**Fields**
- **`name`**: `string` – Full name
- **`email`**: `string` – Lowercased email
- **`role`**: `string` – One of:
  - `admin`
  - `principal`
  - `teacher`
  - `student`
- **`academicUnitId`**: `string | null`
  - For `student`: class ID (e.g. `class-10A`)
  - For `teacher` / `principal`: department or unit
- **`createdAt`**: `Timestamp`
- **`updatedAt`**: `Timestamp`

**RBAC (from `firestore.rules`)**
- User can **read/update** their own profile
- Teacher/Principal/Admin can **read/update** any profile
- Only **admin** can delete profiles

---

### 2. `students`

- **Collection**: `students`
- **Document ID**: internal ID (e.g. `student-001`)

**Suggested Fields**
- `userId`: `string` (link to `users/{uid}`)
- `rollNumber`: `string`
- `name`: `string`
- `email`: `string`
- `classId`: `string` (FK to `academic_units/{classId}`)
- `faceEmbeddingIds`: `string[]` (IDs from face embedding store if needed)
- `createdAt`: `Timestamp`
- `updatedAt`: `Timestamp`

**RBAC**
- Student can read **own** record (same class via `academicUnitId`)
- Teachers/Principals/Admin can **read/write** all students
- Only Principal/Admin can delete

---

### 3. `teachers`

- **Collection**: `teachers`

**Fields (suggested)**
- `userId`: `string` (link to `users/{uid}`)
- `name`: `string`
- `email`: `string`
- `departmentId`: `string`
- `subjects`: `string[]` (FKs to `subjects/{subjectId}`)
- `createdAt`: `Timestamp`
- `updatedAt`: `Timestamp`

**RBAC**
- Any authenticated user can **read**
- Only Principal/Admin can **create/update/delete**

---

### 4. `academic_units` (Classes / Sections)

- **Collection**: `academic_units`

**Fields**
- `name`: `string` (e.g. `B.Tech CS – III A`)
- `code`: `string` (e.g. `CS3A`)
- `teacherId`: `string` (FK to `teachers/{teacherId}`)
- `year`: `number`
- `departmentId`: `string`
- `createdAt`: `Timestamp`
- `updatedAt`: `Timestamp`

**RBAC**
- All authenticated users can **read**
- Only Principal/Admin can **write/delete**

---

### 5. `subjects`

- **Collection**: `subjects`

**Fields**
- `name`: `string` (e.g. `Data Structures`)
- `code`: `string` (e.g. `CS101`)
- `teacherId`: `string`
- `academicUnitIds`: `string[]` (list of classes)
- `createdAt`: `Timestamp`
- `updatedAt`: `Timestamp`

**RBAC**
- All authenticated users can **read**
- Teacher/Principal/Admin can **create/update**
- Only Principal/Admin can **delete**

---

### 6. `attendance`

- **Collection**: `attendance`

**Document Structure (implemented in `FirestoreAttendanceService`)**
- `date`: `Timestamp`
- `subjectId`: `string`
- `classId`: `string`
- `teacherId`: `string`
- `presentStudentIds`: `string[]`
- `absentStudentIds`: `string[]`
- `lateStudentIds`: `string[]`
- `confirmedByTeacher`: `bool`
- `createdAt`: `Timestamp`
- `updatedAt`: `Timestamp`

**RBAC**
- **Read**
  - Students: can read their own sessions (via queries in app)
  - Teachers: can read sessions they created (`teacherId == auth.uid`)
  - Principals/Admin: can read all
- **Create**
  - Only `teacher` can create attendance documents
- **Update**
  - Teacher can update documents where `teacherId == auth.uid`
  - Principal can update any attendance document
- **Delete**
  - Only Principal/Admin can delete

---

### 7. `posts`

- **Collection**: `posts`

**Fields**
- `title`: `string`
- `content`: `string`
- `authorId`: `string` (FK to `users/{uid}`)
- `authorRole`: `string` (e.g. `principal`, `teacher`)
- `targetRoles`: `string[]` (`student`, `teacher`, etc.)
- `createdAt`: `Timestamp`

**RBAC**
- All authenticated users can **read**
- Teacher/Principal/Admin can **create**
- Author or Principal can **update/delete**

---

### 8. Face Embeddings (local / Firestore)

Current implementation keeps face embeddings in a **local repository abstraction** (`FaceRepository`).  
If you choose to store them in Firestore:

- **Collection**: `face_embeddings`
- **Fields**
  - `userId`: `string` (FK to `users/{uid}`)
  - `userName`: `string`
  - `embedding`: `number[]` (List<double>)
  - `createdAt`: `Timestamp`

**RBAC**
- Only Teacher/Principal/Admin should write
- Students should not be able to modify embeddings

---

### RBAC Summary (High-level)

- **Student**
  - Read own `users` profile
  - Read own `students` entry
  - Read own attendance (through app queries)
  - Read teachers, subjects, academic units, posts

- **Teacher**
  - Read/Update any `users` profile (except delete)
  - Manage `students` (create/update)
  - Create/update `subjects`
  - Create `attendance`, update own attendance documents
  - Create posts

- **Principal**
  - Full read on all collections
  - Manage `teachers`, `students`, `subjects`, `academic_units`
  - Update any attendance
  - Moderate all posts

- **Admin**
  - Same as Principal + delete `users` if needed

---

### Where this is enforced

- **App-side services**:
  - `lib/firebase/services/firestore_user_service.dart`
  - `lib/firebase/services/firestore_attendance_service.dart`
  - `lib/firebase/services/firestore_student_service.dart`
  - `lib/firebase/services/firestore_teacher_service.dart`
  - `lib/firebase/services/firestore_subject_service.dart`
  - `lib/firebase/services/firestore_class_service.dart`

- **Security Rules**:
  - `firestore.rules` – All RBAC logic enforced server-side

This gives you a **clear mental model** of Firestore as your “database tables” with roles cleanly separated by the existing RBAC rules.


