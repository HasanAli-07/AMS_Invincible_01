import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import '../../design_system/components/ds_app_bar.dart';
import '../../design_system/components/ds_text.dart';
import '../../design_system/components/ds_card.dart';
import '../../design_system/components/ds_button.dart';
import '../../design_system/components/ds_badge.dart';
import '../../design_system/components/ds_bottom_nav.dart';
import 'attendance_confirm_screen.dart';
import 'attendance_history_screen.dart';
import 'my_subjects_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import '../../design_system/tokens/typography_tokens.dart';
import '../../design_system/tokens/spacing_tokens.dart';
import '../auth/auth_routes.dart';
import '../../design_system/tokens/color_tokens.dart';
import '../../design_system/tokens/radius_tokens.dart';
import '../../ml/attendance_face_recognition_service.dart';
import '../../core/providers/app_provider.dart';
import '../../firebase/services/firestore_teacher_service.dart';
import '../../firebase/services/firestore_subject_service.dart';
import '../../firebase/services/firestore_class_service.dart';
import '../../core/models/user_model.dart';
import '../../core/services/batch_update_service.dart';
import 'package:flutter/foundation.dart';
import '../common/ai_chat_screen.dart';

/// Enhanced Teacher Dashboard with Firestore integration
class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = AppProvider.of(context);
    final currentUser = appState.currentUser;
    final colors = context.colors;

    if (currentUser == null || currentUser.role != UserRole.teacher) {
      // Redirect to login if not authenticated as teacher
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AuthRoutes.login,
          (route) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    Widget content;
    switch (_currentIndex) {
      case 0:
        content = _HomeView(teacherId: currentUser.id);
        break;
      case 1:
        // History - Navigate to separate screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
          );
        });
        content = _HomeView(teacherId: currentUser.id);
        break;
      case 2:
        // Notifications - Navigate to separate screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
        });
        content = _HomeView(teacherId: currentUser.id);
        break;
      case 3:
        // Profile - Navigate to separate screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        });
        content = _HomeView(teacherId: currentUser.id);
        break;
      default:
        content = _HomeView(teacherId: currentUser.id);
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: DSAppBar(
        name: currentUser.name,
        department: currentUser.department ?? 'Department',
        notificationCount: 3,
        onLogoutTap: () {
          appState.logout();
          Navigator.pushNamedAndRemoveUntil(
            context,
            AuthRoutes.login,
            (route) => false,
          );
        },
      ),
      body: content,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Get current class context from HomeView state if possible, 
          // but since access is tricky, we'll default to General Context
          // or ideally, user picks context in Chat Screen.
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AiChatScreen(className: 'General'),
            ),
          );
        },
        label: const Text('Ask AI'),
        icon: const Icon(Icons.chat_bubble_outline),
        backgroundColor: colors.accentPrimary,
      ),
      bottomNavigationBar: DSBottomNav(
        currentIndex: _currentIndex == 0 ? 0 : 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MySubjectsScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          } else {
            setState(() => _currentIndex = 0);
          }
        },
        items: const [
          DSBottomNavItem(icon: Icons.home_outlined, label: 'Home'),
          DSBottomNavItem(icon: Icons.menu_book_outlined, label: 'Subjects'),
          DSBottomNavItem(icon: Icons.notifications_outlined, label: 'Alerts'),
          DSBottomNavItem(icon: Icons.person_outline, label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeView extends StatefulWidget {
  final String teacherId;

  const _HomeView({required this.teacherId});

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final FirestoreTeacherService _teacherService = FirestoreTeacherService();
  final FirestoreSubjectService _subjectService = FirestoreSubjectService();
  final FirestoreClassService _classService = FirestoreClassService();

  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _classes = [];
  bool _isLoading = true;
  String? _selectedSubjectId;
  String? _selectedClassId;
  Map<String, dynamic>? _teacherData;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    setState(() => _isLoading = true);
    try {
      // Get teacher data
      final teacher = await _teacherService.getTeacherById(widget.teacherId);
      if (teacher != null) {
        _teacherData = teacher;
        final subjectIds = (teacher['subjectIds'] as List<dynamic>?)?.cast<String>() ?? [];
        
        // Fetch all subjects
        final allSubjects = await _subjectService.getAllSubjects();
        _subjects = allSubjects.where((s) => subjectIds.contains(s['id'])).toList();
        
        // Fetch all classes
        _classes = await _classService.getAllClasses();
        
        if (_subjects.isNotEmpty) {
          _selectedSubjectId = _subjects.first['id'] as String;
          // Update classes for first subject
          _updateClassesForSubject(_selectedSubjectId!);
        }
      }
    } catch (e) {
      debugPrint('Error loading teacher data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Update available classes based on selected subject's department
  Future<void> _updateClassesForSubject(String subjectId) async {
    try {
      final subject = _subjects.firstWhere(
        (s) => s['id'] == subjectId,
        orElse: () => {},
      );
      
      if (subject.isNotEmpty) {
        final subjectDepartment = (subject['department'] as String? ?? '').trim().toLowerCase();
        debugPrint('Updating classes for subject department: $subjectDepartment');
        
        // Fetch all classes to have a backup
        final allAvailableClasses = await _classService.getAllClasses();
        debugPrint('Total classes found in system: ${allAvailableClasses.length}');
        
        // Filter classes by department (fuzzy match)
        if (subjectDepartment.isNotEmpty) {
          _classes = allAvailableClasses.where((c) {
            final classDept = (c['department'] as String? ?? '').trim().toLowerCase();
            return classDept == subjectDepartment || 
                   classDept.contains(subjectDepartment) || 
                   subjectDepartment.contains(classDept);
          }).toList();
          debugPrint('Filtered classes for department "$subjectDepartment": ${_classes.length}');
        } else {
          _classes = allAvailableClasses;
        }
        
        // If no classes found for this department, fall back to all classes
        if (_classes.isEmpty && allAvailableClasses.isNotEmpty) {
          debugPrint('No classes found for department, falling back to all classes');
          _classes = allAvailableClasses;
        }
        
        // Optional: Sort classes by name
        _classes.sort((a, b) => (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''));
        
        // Auto-select first class or maintain selection if possible
        if (_classes.isNotEmpty) {
          // If previous selection is still in list, keep it
          if (_selectedClassId != null && _classes.any((c) => c['id'] == _selectedClassId)) {
            // Keep existing selection
          } else {
            _selectedClassId = _classes.first['id'] as String;
          }
        } else {
          _selectedClassId = null;
        }
        
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error updating classes for subject: $e');
    }
  }

  /// Force Sync Database with Batch 5
  Future<void> _handleForceSync(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      final migrator = BatchUpdateService();
      final result = await migrator.updateAllStudentsToBatch5();
      
      if (context.mounted) Navigator.pop(context); // Close loading
      
      if (result['success'] == true) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('Database successfully synced with Batch 5 and CE department!'),
             backgroundColor: Colors.green,
           ),
         );
         // Reload data
         await _loadTeacherData();
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Sync failed: ${result['error']}'), backgroundColor: Colors.red),
         );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: colors.textSecondary),
            const SizedBox(height: SpacingTokens.space16),
            DSText(
              'No subjects assigned',
              role: TypographyRole.headline,
            ),
            const SizedBox(height: SpacingTokens.space8),
            DSText(
              'Please contact administrator to assign subjects',
              role: TypographyRole.body,
              style: TextStyle(color: colors.textSecondary),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: Insets.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Face Recognition Attendance Section
          Wrap(
            spacing: SpacingTokens.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DSText(
                'Face Recognition Attendance',
                role: TypographyRole.headline,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const DSBadge(label: 'AI POWERED', variant: DSBadgeVariant.success),
            ],
          ),
          Insets.spaceVertical16,
          DSCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DSText(
                    'Take a photo of your class and AI will automatically recognize students and mark attendance.',
                    role: TypographyRole.body,
                  ),
                ),
                const SizedBox(width: SpacingTokens.space12),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colors.success.withOpacity(0.1),
                    borderRadius: RadiusTokens.button,
                  ),
                  child: Icon(
                    Icons.face,
                    color: colors.success,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
          Insets.spaceVertical24,
          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: colors.borderSubtle)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.space16),
                child: DSText(
                  'SELECT SUBJECT & CLASS',
                  role: TypographyRole.caption,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(child: Divider(color: colors.borderSubtle)),
            ],
          ),
          Insets.spaceVertical24,
          // Date Selection
          DSText(
            'DATE',
            role: TypographyRole.caption,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Insets.spaceVertical8,
          InkWell(
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: colors.accentPrimary,
                        onPrimary: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (pickedDate != null) {
                setState(() {
                  _selectedDate = pickedDate;
                });
              }
            },
            child: Container(
              padding: Insets.buttonPadding,
              decoration: BoxDecoration(
                color: colors.backgroundSurface,
                border: Border.all(color: colors.borderSubtle),
                borderRadius: RadiusTokens.button,
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: colors.accentPrimary, size: 20),
                  const SizedBox(width: SpacingTokens.space12),
                  DSText(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    role: TypographyRole.body,
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_drop_down, color: colors.textSecondary),
                ],
              ),
            ),
          ),
          Insets.spaceVertical16,
          // Temporary Sync Button (Only if no classes found)
          if (_classes.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: RadiusTokens.card,
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const DSText(
                      'No Classes Available',
                      role: TypographyRole.title,
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const DSText(
                      'The database needs to be synced with Batch 5 and Computer Engineering department.',
                      role: TypographyRole.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    DSButton(
                      label: 'Force Sync Database (Batch 5)',
                      icon: Icons.sync,
                      onPressed: () => _handleForceSync(context),
                    ),
                  ],
                ),
              ),
            ),
          // Subject Dropdown
          DSText(
            'SUBJECT',
            role: TypographyRole.caption,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Insets.spaceVertical8,
          _DropdownField(
            value: _selectedSubjectId ?? '',
            onChanged: (value) {
              if (value != null && value.isNotEmpty) {
                setState(() {
                  _selectedSubjectId = value;
                  // When subject changes, update available classes based on subject's department
                  _updateClassesForSubject(value);
                });
              }
            },
            items: _subjects.map((subject) {
              final name = subject['name'] as String? ?? '';
              final code = subject['code'] as String? ?? '';
              return DropdownMenuItem<String>(
                value: subject['id'] as String,
                child: DSText('$code - $name', role: TypographyRole.body, maxLines: 1),
              );
            }).toList(),
            isEmpty: _subjects.isEmpty,
          ),
          Insets.spaceVertical16,
          // Class/Batch Dropdown
          DSText(
            'CLASS / BATCH',
            role: TypographyRole.caption,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Insets.spaceVertical8,
          _DropdownField(
            value: _selectedClassId ?? '',
            onChanged: (value) {
              setState(() => _selectedClassId = value);
            },
            items: _classes.map((classData) {
              final name = classData['name'] as String? ?? '';
              final dept = classData['department'] as String? ?? '';
              return DropdownMenuItem<String>(
                value: classData['id'] as String,
                child: DSText('$name ($dept)', role: TypographyRole.body, maxLines: 1),
              );
            }).toList(),
            isEmpty: _classes.isEmpty,
          ),
          Insets.spaceVertical24,
          // Photo Options
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 400;
              return isSmall
                  ? Column(
                      children: [
                        _PhotoOptionCard(
                          icon: Icons.camera_alt,
                          label: 'Camera',
                          onTap: () => _handleCamera(context),
                        ),
                        Insets.spaceVertical12,
                        _PhotoOptionCard(
                          icon: Icons.upload_file,
                          label: 'Upload',
                          onTap: () => _handleUpload(context),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _PhotoOptionCard(
                            icon: Icons.camera_alt,
                            label: 'Camera',
                            onTap: () => _handleCamera(context),
                          ),
                        ),
                        const SizedBox(width: SpacingTokens.space12),
                        Expanded(
                          child: _PhotoOptionCard(
                            icon: Icons.upload_file,
                            label: 'Upload',
                            onTap: () => _handleUpload(context),
                          ),
                        ),
                      ],
                    );
            },
          ),
          Insets.spaceVertical32,
        ],
      ),
    );
  }

  /// Open camera to capture class photo for attendance
  Future<void> _handleCamera(BuildContext context) async {
    if (_selectedSubjectId == null || _selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select subject and class first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

      if (image == null) return;

      await _processImage(context, image.path, await image.readAsBytes());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $e')),
      );
    }
  }

  /// Open gallery/file picker to upload class photo for attendance
  Future<void> _handleUpload(BuildContext context) async {
    if (_selectedSubjectId == null || _selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select subject and class first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      await _processImage(context, image.path, await image.readAsBytes());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: $e')),
      );
    }
  }

  Future<void> _processImage(BuildContext context, String imagePath, Uint8List imageBytes) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Process with face recognition
      final faceRecognitionService = AttendanceFaceRecognitionService();
      final result = await faceRecognitionService.processAttendancePhoto(
        imageBytes: imageBytes,
      );

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Navigate to confirmation screen
      if (context.mounted) {
        final selectedSubject = _subjects.firstWhere(
          (s) => s['id'] == _selectedSubjectId,
          orElse: () => {},
        );
        final selectedClass = _classes.firstWhere(
          (c) => c['id'] == _selectedClassId,
          orElse: () => {},
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceConfirmScreen(
              recognitionResult: result,
              imagePath: imagePath,
              subjectId: _selectedSubjectId!,
              subjectName: selectedSubject['name'] as String? ?? '',
              subjectCode: selectedSubject['code'] as String? ?? '',
              classId: _selectedClassId!,
              className: selectedClass['name'] as String? ?? '',
              teacherId: widget.teacherId,
              date: _selectedDate,
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Face recognition error: $e'),
            backgroundColor: Colors.orange,
          ),
        );

        // Still navigate to confirmation screen even if recognition fails
        final selectedSubject = _subjects.firstWhere(
          (s) => s['id'] == _selectedSubjectId,
          orElse: () => {},
        );
        final selectedClass = _classes.firstWhere(
          (c) => c['id'] == _selectedClassId,
          orElse: () => {},
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceConfirmScreen(
              imagePath: imagePath,
              subjectId: _selectedSubjectId!,
              subjectName: selectedSubject['name'] as String? ?? '',
              subjectCode: selectedSubject['code'] as String? ?? '',
              classId: _selectedClassId!,
              className: selectedClass['name'] as String? ?? '',
              teacherId: widget.teacherId,
              date: _selectedDate,
            ),
          ),
        );
      }
    }
  }
}

class _DropdownField extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  final List<DropdownMenuItem<String>> items;
  final bool isEmpty;

  const _DropdownField({
    required this.value,
    required this.onChanged,
    required this.items,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: Insets.buttonPadding,
      decoration: BoxDecoration(
        color: colors.backgroundSurface,
        border: Border.all(color: colors.borderSubtle),
        borderRadius: RadiusTokens.button,
      ),
      child: DropdownButton<String>(
        value: (value.isEmpty || !items.any((item) => item.value == value)) && items.isNotEmpty 
            ? items.first.value 
            : value.isEmpty 
                ? null 
                : value,
        isExpanded: true,
        underline: const SizedBox(),
        icon: Icon(Icons.arrow_drop_down, color: colors.textSecondary),
        items: items,
        onChanged: isEmpty ? null : onChanged,
        hint: isEmpty
            ? DSText(
                'No items available',
                role: TypographyRole.body,
                style: TextStyle(color: colors.textSecondary),
              )
            : null,
      ),
    );
  }
}

class _PhotoOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoOptionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: RadiusTokens.card,
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.space24),
        decoration: BoxDecoration(
          border: Border.all(color: colors.borderSubtle, style: BorderStyle.solid),
          borderRadius: RadiusTokens.card,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.accentPrimary, size: 32),
            Insets.spaceVertical8,
            DSText(label, role: TypographyRole.body),
          ],
        ),
      ),
    );
  }
}