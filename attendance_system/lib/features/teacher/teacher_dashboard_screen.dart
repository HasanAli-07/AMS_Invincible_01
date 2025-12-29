import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

/// Enhanced Teacher Dashboard with better UX and no overflow
class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _currentIndex = 0;
  String? selectedSubject;
  String? selectedBatch;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Widget content;
    switch (_currentIndex) {
      case 0:
        content = _HomeView(
          selectedSubject: selectedSubject,
          selectedBatch: selectedBatch,
          onSubjectChanged: (value) => setState(() => selectedSubject = value),
          onBatchChanged: (value) => setState(() => selectedBatch = value),
        );
        break;
      case 1:
        // History - Navigate to separate screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen()),
          );
        });
        content = _HomeView(
          selectedSubject: selectedSubject,
          selectedBatch: selectedBatch,
          onSubjectChanged: (value) => setState(() => selectedSubject = value),
          onBatchChanged: (value) => setState(() => selectedBatch = value),
        );
        break;
      case 2:
        // Notifications - Navigate to separate screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          );
        });
        content = _HomeView(
          selectedSubject: selectedSubject,
          selectedBatch: selectedBatch,
          onSubjectChanged: (value) => setState(() => selectedSubject = value),
          onBatchChanged: (value) => setState(() => selectedBatch = value),
        );
        break;
      case 3:
        // Profile - Navigate to separate screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        });
        content = _HomeView(
          selectedSubject: selectedSubject,
          selectedBatch: selectedBatch,
          onSubjectChanged: (value) => setState(() => selectedSubject = value),
          onBatchChanged: (value) => setState(() => selectedBatch = value),
        );
        break;
      default:
        content = _HomeView(
          selectedSubject: selectedSubject,
          selectedBatch: selectedBatch,
          onSubjectChanged: (value) => setState(() => selectedSubject = value),
          onBatchChanged: (value) => setState(() => selectedBatch = value),
        );
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: DSAppBar(
        name: 'Prof. Smith',
        department: 'Computer Science Dept.',
        notificationCount: 3,
        onLogoutTap: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AuthRoutes.login,
            (route) => false,
          );
        },
      ),
      body: content,
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

class _HomeView extends StatelessWidget {
  final String? selectedSubject;
  final String? selectedBatch;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<String?> onBatchChanged;

  const _HomeView({
    required this.selectedSubject,
    required this.selectedBatch,
    required this.onSubjectChanged,
    required this.onBatchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: Insets.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // WhatsApp Attendance Section
          Wrap(
            spacing: SpacingTokens.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DSText(
                'WhatsApp Attendance',
                role: TypographyRole.headline,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const DSBadge(label: 'PRIMARY', variant: DSBadgeVariant.success),
            ],
          ),
          Insets.spaceVertical16,
          DSCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DSText(
                    'Snap a clear photo of the classroom and send it to our AI bot for instant analysis.',
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
                    Icons.qr_code_scanner,
                    color: colors.success,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
          Insets.spaceVertical12,
          DSButton(
            label: 'Open WhatsApp',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening WhatsApp...')),
              );
            },
            icon: Icons.chat,
          ),
          Insets.spaceVertical16,
          // Bot Number - Responsive Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 350;
              return isSmall
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.smart_toy, color: colors.accentPrimary, size: 20),
                            const SizedBox(width: SpacingTokens.space8),
                            DSText(
                              'Bot Number',
                              role: TypographyRole.body,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Insets.spaceVertical8,
                        Row(
                          children: [
                            Expanded(
                              child: DSText(
                                '+1 (555) 019-2834',
                                role: TypographyRole.body,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.copy, size: 18, color: colors.accentPrimary),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Bot number copied!')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(Icons.smart_toy, color: colors.accentPrimary, size: 20),
                        const SizedBox(width: SpacingTokens.space8),
                        DSText(
                          'Bot Number',
                          role: TypographyRole.body,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        DSText(
                          '+1 (555) 019-2834',
                          role: TypographyRole.body,
                          maxLines: 1,
                        ),
                        const SizedBox(width: SpacingTokens.space8),
                        IconButton(
                          icon: Icon(Icons.copy, size: 18, color: colors.accentPrimary),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Bot number copied!')),
                            );
                          },
                        ),
                      ],
                    );
            },
          ),
          Insets.spaceVertical24,
          // Enhanced Timeline with proper visual flow
          _EnhancedTimelineSection(),
          Insets.spaceVertical32,
          // Divider
          Row(
            children: [
              Expanded(child: Divider(color: colors.borderSubtle)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.space16),
                child: DSText(
                  'OR USE APP',
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
          Insets.spaceVertical32,
          // Manual Entry Section
          Wrap(
            spacing: SpacingTokens.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DSText(
                'Manual Entry',
                role: TypographyRole.headline,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const DSBadge(label: 'BACKUP', variant: DSBadgeVariant.secondary),
            ],
          ),
          Insets.spaceVertical16,
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
            value: selectedSubject ?? 'CS-101 Data Structures',
            onChanged: onSubjectChanged,
            items: const [
              'CS-101 Data Structures',
              'CS-201 Algorithms',
              'CS-301 Database Systems',
            ],
          ),
          Insets.spaceVertical16,
          DSText(
            'BATCH / SEMESTER',
            role: TypographyRole.caption,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Insets.spaceVertical8,
          _DropdownField(
            value: selectedBatch ?? '2024-A (Sem 3)',
            onChanged: onBatchChanged,
            items: const [
              '2024-A (Sem 3)',
              '2024-B (Sem 3)',
              '2023-A (Sem 5)',
            ],
          ),
          Insets.spaceVertical16,
          // Photo Options - Responsive Grid
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
          Insets.spaceVertical16,
          DSButton(
            label: 'Analyze Class Photo',
            onPressed: () {
              Navigator.pushNamed(context, '/teacher/attendance-confirm');
            },
            icon: Icons.bar_chart,
          ),
          Insets.spaceVertical32,
        ],
      ),
    );
  }

  /// Open camera to capture class photo for attendance
  Future<void> _handleCamera(BuildContext context) async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (image == null) return;

      // TODO: Integrate with FaceRecognitionService to auto-mark attendance.
      // For now, navigate to confirmation screen with the captured photo context.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo captured for attendance')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AttendanceConfirmScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera error: $e')),
      );
    }
  }

  /// Open gallery/file picker to upload class photo for attendance
  Future<void> _handleUpload(BuildContext context) async {
    final picker = ImagePicker();
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      // TODO: Integrate with FaceRecognitionService to analyze uploaded photo.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo selected for attendance')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AttendanceConfirmScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: $e')),
      );
    }
  }
}

/// Enhanced Timeline with proper visual flow and animations
class _EnhancedTimelineSection extends StatefulWidget {
  @override
  State<_EnhancedTimelineSection> createState() => _EnhancedTimelineSectionState();
}

class _EnhancedTimelineSectionState extends State<_EnhancedTimelineSection> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DSText(
          'LIVE STATUS: TODAY, 9:30 AM',
          role: TypographyRole.caption,
          style: TextStyle(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        Insets.spaceVertical16,
        // Timeline with connecting lines
        Column(
          children: [
            _TimelineItem(
              icon: Icons.check_circle,
              iconColor: colors.success,
              title: 'Image Sent',
              subtitle: '9:30 AM via WhatsApp',
              isCompleted: true,
              isLast: false,
            ),
            _TimelineItem(
              icon: Icons.refresh,
              iconColor: colors.accentPrimary,
              title: 'Processing Faces',
              subtitle: 'AI is analyzing student count...',
              isCompleted: false,
              isActive: true,
              isLast: false,
            ),
            _TimelineItem(
              icon: Icons.radio_button_unchecked,
              iconColor: colors.textSecondary,
              title: 'Pending Confirmation',
              subtitle: 'Waiting for your review',
              isCompleted: false,
              isLast: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isActive;
  final bool isLast;

  const _TimelineItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.isCompleted = false,
    this.isActive = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isCompleted || isActive)
                    ? iconColor.withOpacity(0.1)
                    : colors.backgroundElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted || isActive ? iconColor : colors.borderSubtle,
                  width: 2,
                ),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: SpacingTokens.space4),
                decoration: BoxDecoration(
                  color: isCompleted ? iconColor.withOpacity(0.3) : colors.borderSubtle,
                ),
              ),
          ],
        ),
        const SizedBox(width: SpacingTokens.space12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: SpacingTokens.space8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(
                  title,
                  role: TypographyRole.body,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isActive ? colors.accentPrimary : colors.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  Insets.spaceVertical4,
                  DSText(
                    subtitle,
                    role: TypographyRole.caption,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  final List<String> items;

  const _DropdownField({
    required this.value,
    required this.onChanged,
    required this.items,
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
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        icon: Icon(Icons.arrow_drop_down, color: colors.textSecondary),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: DSText(item, role: TypographyRole.body, maxLines: 1),
          );
        }).toList(),
        onChanged: onChanged,
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
