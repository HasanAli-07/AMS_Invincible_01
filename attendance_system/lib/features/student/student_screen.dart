import 'package:flutter/material.dart';

import '../../design_system/components/ds_app_bar.dart';
import '../../design_system/components/ds_text.dart';
import '../../design_system/components/ds_card.dart';
import '../../design_system/components/ds_badge.dart';
import '../../design_system/components/ds_bottom_nav.dart';
import '../../design_system/components/ds_chart.dart';
import '../../design_system/tokens/typography_tokens.dart';
import '../../design_system/tokens/spacing_tokens.dart';
import '../../design_system/tokens/color_tokens.dart';
import '../../design_system/tokens/radius_tokens.dart';
import '../auth/auth_routes.dart';

/// Student Dashboard - Read-only, Individual-level access
class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Widget content;
    switch (_currentIndex) {
      case 1:
        content = _SubjectWiseView();
        break;
      case 2:
        content = _HistoryView();
        break;
      case 3:
        content = _TimetableView();
        break;
      case 4:
        content = _PostsView();
        break;
      default:
        content = _OverviewView();
    }

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: DSAppBar(
        name: 'John Doe',
        department: 'Class 10-A',
        notificationCount: 2,
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
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          DSBottomNavItem(icon: Icons.dashboard_outlined, label: 'Overview'),
          DSBottomNavItem(icon: Icons.menu_book_outlined, label: 'Subjects'),
          DSBottomNavItem(icon: Icons.history_outlined, label: 'History'),
          DSBottomNavItem(icon: Icons.schedule_outlined, label: 'Schedule'),
          DSBottomNavItem(icon: Icons.article_outlined, label: 'Posts'),
        ],
      ),
    );
  }
}

/// Overview Dashboard - Overall attendance stats
class _OverviewView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: Insets.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Overall Attendance Card
          DSCard(
            child: Column(
              children: [
                DSText(
                  'Overall Attendance',
                  role: TypographyRole.caption,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Insets.spaceVertical16,
                DSText(
                  '87.5%',
                  role: TypographyRole.displayLarge,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 48,
                  ),
                ),
                Insets.spaceVertical12,
                DSBadge(
                  label: 'SAFE',
                  variant: DSBadgeVariant.success,
                ),
                Insets.spaceVertical24,
                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        label: 'Conducted',
                        value: '120',
                        icon: Icons.event_available,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: colors.borderSubtle,
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Attended',
                        value: '105',
                        icon: Icons.check_circle,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: colors.borderSubtle,
                    ),
                    Expanded(
                      child: _StatItem(
                        label: 'Missed',
                        value: '15',
                        icon: Icons.cancel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Insets.spaceVertical24,
          // 7-Day Trend Chart
          DSCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(
                  '7-Day Attendance Trend',
                  role: TypographyRole.headline,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Insets.spaceVertical16,
                DSLineChart(
                  values: [85.0, 88.0, 87.0, 89.0, 86.0, 88.0, 87.5],
                  labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
                  unit: '%',
                  maxY: 100,
                ),
              ],
            ),
          ),
          Insets.spaceVertical24,
          // Insights Cards
          DSText(
            'INSIGHTS',
            role: TypographyRole.headline,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Insets.spaceVertical16,
          _InsightCard(
            icon: Icons.trending_up,
            iconColor: colors.success,
            title: 'Remaining Safe Absences',
            value: 'You can miss 5 more lectures safely',
            subtitle: 'To maintain 75% threshold',
          ),
          Insets.spaceVertical12,
          _InsightCard(
            icon: Icons.calendar_today,
            iconColor: colors.accentPrimary,
            title: 'Required Attendance',
            value: 'Attend 12 of 15 remaining lectures',
            subtitle: 'To reach 90% target',
          ),
          Insets.spaceVertical12,
          _InsightCard(
            icon: Icons.local_fire_department,
            iconColor: colors.warning,
            title: 'Current Streak',
            value: '8 consecutive present days',
            subtitle: 'Keep it up!',
          ),
          Insets.spaceVertical24,
          // Alerts Section
          DSText(
            'ALERTS',
            role: TypographyRole.headline,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Insets.spaceVertical16,
          _AlertCard(
            icon: Icons.info_outline,
            iconColor: colors.accentPrimary,
            title: 'Attendance Status',
            message: 'Your attendance is above the safe threshold.',
            severity: 'INFO',
          ),
          Insets.spaceVertical32,
        ],
      ),
    );
  }
}

/// Subject-wise Attendance View
class _SubjectWiseView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: Insets.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DSText(
            'SUBJECT-WISE ATTENDANCE',
            role: TypographyRole.headline,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Insets.spaceVertical16,
          _SubjectCard(
            subjectName: 'Mathematics',
            subjectCode: 'MATH-101',
            totalLectures: 30,
            attendedLectures: 28,
            percentage: 93.3,
            lastAttendanceDate: 'Oct 24, 2023',
          ),
          Insets.spaceVertical12,
          _SubjectCard(
            subjectName: 'Physics',
            subjectCode: 'PHY-101',
            totalLectures: 28,
            attendedLectures: 25,
            percentage: 89.3,
            lastAttendanceDate: 'Oct 23, 2023',
          ),
          Insets.spaceVertical12,
          _SubjectCard(
            subjectName: 'Chemistry',
            subjectCode: 'CHEM-101',
            totalLectures: 30,
            attendedLectures: 26,
            percentage: 86.7,
            lastAttendanceDate: 'Oct 24, 2023',
          ),
          Insets.spaceVertical12,
          _SubjectCard(
            subjectName: 'English',
            subjectCode: 'ENG-101',
            totalLectures: 32,
            attendedLectures: 26,
            percentage: 81.3,
            lastAttendanceDate: 'Oct 24, 2023',
            isWarning: true,
          ),
          Insets.spaceVertical32,
        ],
      ),
    );
  }
}

/// Attendance History View
class _HistoryView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: Insets.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterPill(label: 'All Subjects', isSelected: true),
                const SizedBox(width: SpacingTokens.space8),
                _FilterPill(label: 'This Month', isSelected: false),
                const SizedBox(width: SpacingTokens.space8),
                _FilterPill(label: 'Last 30 Days', isSelected: false),
              ],
            ),
          ),
          Insets.spaceVertical24,
          DSText(
            'RECENT ATTENDANCE',
            role: TypographyRole.headline,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Insets.spaceVertical16,
          _HistoryItem(
            date: 'Oct 24, 2023',
            subject: 'Mathematics',
            time: '09:00 AM',
            status: 'PRESENT',
            isPresent: true,
          ),
          Insets.spaceVertical12,
          _HistoryItem(
            date: 'Oct 24, 2023',
            subject: 'Physics',
            time: '10:30 AM',
            status: 'PRESENT',
            isPresent: true,
          ),
          Insets.spaceVertical12,
          _HistoryItem(
            date: 'Oct 24, 2023',
            subject: 'Chemistry',
            time: '02:00 PM',
            status: 'PRESENT',
            isPresent: true,
          ),
          Insets.spaceVertical12,
          _HistoryItem(
            date: 'Oct 23, 2023',
            subject: 'English',
            time: '11:00 AM',
            status: 'ABSENT',
            isPresent: false,
          ),
          Insets.spaceVertical12,
          _HistoryItem(
            date: 'Oct 23, 2023',
            subject: 'Mathematics',
            time: '09:00 AM',
            status: 'PRESENT',
            isPresent: true,
          ),
          Insets.spaceVertical32,
        ],
      ),
    );
  }
}

/// Today's Timetable/Schedule View
class _TimetableView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    final today = '${now.day} ${_getMonthName(now.month)}, ${now.year}';

    return SingleChildScrollView(
      padding: Insets.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Today's Date Header
          Row(
            children: [
              Icon(Icons.calendar_today, color: colors.accentPrimary, size: 20),
              const SizedBox(width: SpacingTokens.space8),
              DSText(
                'Today\'s Schedule',
                role: TypographyRole.headline,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              DSText(
                today,
                role: TypographyRole.body,
                style: TextStyle(color: colors.textSecondary),
              ),
            ],
          ),
          Insets.spaceVertical16,
          // Schedule Timeline
          _ScheduleTimelineItem(
            time: '09:00 AM - 10:00 AM',
            subject: 'Mathematics',
            subjectCode: 'MATH-101',
            location: 'Room 301',
            isCompleted: true,
            isCurrent: false,
          ),
          _ScheduleTimelineItem(
            time: '10:30 AM - 11:30 AM',
            subject: 'Physics',
            subjectCode: 'PHY-101',
            location: 'Room 205',
            isCompleted: true,
            isCurrent: false,
          ),
          _ScheduleTimelineItem(
            time: '11:45 AM - 12:45 PM',
            subject: 'Chemistry',
            subjectCode: 'CHEM-101',
            location: 'Lab 101',
            isCompleted: false,
            isCurrent: true,
          ),
          _ScheduleTimelineItem(
            time: '02:00 PM - 03:00 PM',
            subject: 'English',
            subjectCode: 'ENG-101',
            location: 'Room 102',
            isCompleted: false,
            isCurrent: false,
          ),
          Insets.spaceVertical24,
          // Upcoming Classes Section
          DSText(
            'UPCOMING THIS WEEK',
            role: TypographyRole.headline,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Insets.spaceVertical16,
          _UpcomingClassCard(
            day: 'Tomorrow',
            date: 'Oct 25, 2023',
            subject: 'Mathematics',
            time: '09:00 AM',
            location: 'Room 301',
          ),
          Insets.spaceVertical12,
          _UpcomingClassCard(
            day: 'Friday',
            date: 'Oct 26, 2023',
            subject: 'Physics',
            time: '10:30 AM',
            location: 'Room 205',
            isHoliday: true,
          ),
          Insets.spaceVertical32,
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

class _ScheduleTimelineItem extends StatelessWidget {
  final String time;
  final String subject;
  final String subjectCode;
  final String location;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLast;

  const _ScheduleTimelineItem({
    required this.time,
    required this.subject,
    required this.subjectCode,
    required this.location,
    required this.isCompleted,
    required this.isCurrent,
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
              width: 80,
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.space4),
              child: DSText(
                time,
                role: TypographyRole.caption,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isCurrent ? colors.accentPrimary : colors.textSecondary,
                ),
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isCurrent
                    ? colors.accentPrimary
                    : isCompleted
                        ? colors.success
                        : colors.backgroundElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent
                      ? colors.accentPrimary
                      : isCompleted
                          ? colors.success
                          : colors.borderSubtle,
                  width: 2,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 100,
                margin: const EdgeInsets.symmetric(vertical: SpacingTokens.space4),
                decoration: BoxDecoration(
                  color: colors.borderSubtle,
                ),
              ),
          ],
        ),
        const SizedBox(width: SpacingTokens.space16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : SpacingTokens.space16),
            child: DSCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DSText(
                              subject,
                              role: TypographyRole.title,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Insets.spaceVertical4,
                            DSText(
                              subjectCode,
                              role: TypographyRole.caption,
                            ),
                          ],
                        ),
                      ),
                      if (isCurrent)
                        DSBadge(
                          label: 'NOW',
                          variant: DSBadgeVariant.primary,
                        )
                      else if (isCompleted)
                        Icon(
                          Icons.check_circle,
                          color: colors.success,
                          size: 24,
                        ),
                    ],
                  ),
                  Insets.spaceVertical12,
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: colors.textSecondary),
                      const SizedBox(width: SpacingTokens.space4),
                      DSText(
                        location,
                        role: TypographyRole.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UpcomingClassCard extends StatelessWidget {
  final String day;
  final String date;
  final String subject;
  final String time;
  final String location;
  final bool isHoliday;

  const _UpcomingClassCard({
    required this.day,
    required this.date,
    required this.subject,
    required this.time,
    required this.location,
    this.isHoliday = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DSCard(
      child: Row(
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: isHoliday ? colors.warning : colors.accentPrimary,
              borderRadius: RadiusTokens.pillSmall,
            ),
          ),
          const SizedBox(width: SpacingTokens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DSText(
                        subject,
                        role: TypographyRole.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isHoliday)
                      DSBadge(
                        label: 'HOLIDAY',
                        variant: DSBadgeVariant.warning,
                      ),
                  ],
                ),
                Insets.spaceVertical8,
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: colors.textSecondary),
                    const SizedBox(width: SpacingTokens.space4),
                    DSText(
                      '$day, $date',
                      role: TypographyRole.caption,
                    ),
                    const SizedBox(width: SpacingTokens.space16),
                    Icon(Icons.access_time, size: 14, color: colors.textSecondary),
                    const SizedBox(width: SpacingTokens.space4),
                    DSText(
                      time,
                      role: TypographyRole.caption,
                    ),
                  ],
                ),
                Insets.spaceVertical4,
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: colors.textSecondary),
                    const SizedBox(width: SpacingTokens.space4),
                    DSText(
                      location,
                      role: TypographyRole.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Posts View
class _PostsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: Insets.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DSText(
            'POSTS',
            role: TypographyRole.headline,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Insets.spaceVertical16,
          _PostCard(
            title: 'Mid-Term Exam Schedule Released',
            content: 'The mid-term examination schedule for Semester 1 has been finalized. Please check your timetable.',
            date: 'Oct 20, 2023',
            category: 'ACADEMIC',
          ),
          Insets.spaceVertical12,
          _PostCard(
            title: 'Holiday Notice',
            content: 'The institution will remain closed on Oct 26, 2023 for Diwali celebrations.',
            date: 'Oct 18, 2023',
            category: 'EVENTS',
          ),
          Insets.spaceVertical12,
          _PostCard(
            title: 'Library Hours Extended',
            content: 'Library will remain open until 8 PM during exam preparation period.',
            date: 'Oct 15, 2023',
            category: 'GENERAL',
          ),
          Insets.spaceVertical32,
        ],
      ),
    );
  }
}

// Helper Widgets

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: [
        Icon(icon, color: colors.accentPrimary, size: 24),
        Insets.spaceVertical8,
        DSText(
          value,
          role: TypographyRole.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Insets.spaceVertical4,
        DSText(
          label,
          role: TypographyRole.caption,
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DSCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: RadiusTokens.button,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: SpacingTokens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(
                  title,
                  role: TypographyRole.caption,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Insets.spaceVertical4,
                DSText(
                  value,
                  role: TypographyRole.body,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: SpacingTokens.space4),
                DSText(
                  subtitle,
                  role: TypographyRole.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String severity;

  const _AlertCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.severity,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.space16),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: RadiusTokens.card,
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: SpacingTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(
                  title,
                  role: TypographyRole.body,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Insets.spaceVertical4,
                DSText(
                  message,
                  role: TypographyRole.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String subjectName;
  final String subjectCode;
  final int totalLectures;
  final int attendedLectures;
  final double percentage;
  final String lastAttendanceDate;
  final bool isWarning;

  const _SubjectCard({
    required this.subjectName,
    required this.subjectCode,
    required this.totalLectures,
    required this.attendedLectures,
    required this.percentage,
    required this.lastAttendanceDate,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DSText(
                      subjectName,
                      role: TypographyRole.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Insets.spaceVertical4,
                    DSText(
                      subjectCode,
                      role: TypographyRole.caption,
                    ),
                  ],
                ),
              ),
              DSBadge(
                label: '${percentage.toStringAsFixed(1)}%',
                variant: isWarning ? DSBadgeVariant.warning : DSBadgeVariant.success,
              ),
            ],
          ),
          Insets.spaceVertical16,
          Row(
            children: [
              Expanded(
                child: _MiniStat(label: 'Total', value: totalLectures.toString()),
              ),
              Expanded(
                child: _MiniStat(label: 'Attended', value: attendedLectures.toString()),
              ),
              Expanded(
                child: _MiniStat(label: 'Missed', value: '${totalLectures - attendedLectures}'),
              ),
            ],
          ),
          Insets.spaceVertical12,
          DSText(
            'Last attendance: $lastAttendanceDate',
            role: TypographyRole.caption,
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DSText(
          value,
          role: TypographyRole.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Insets.spaceVertical4,
        DSText(
          label,
          role: TypographyRole.caption,
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterPill({
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: () {},
      borderRadius: RadiusTokens.button,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.space16,
          vertical: SpacingTokens.space8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.backgroundSurface,
          borderRadius: RadiusTokens.button,
          border: Border.all(
            color: isSelected ? colors.accentPrimary : colors.borderSubtle,
          ),
        ),
        child: DSText(
          label,
          role: TypographyRole.body,
          style: TextStyle(
            color: isSelected ? colors.textOnAccent : colors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String date;
  final String subject;
  final String time;
  final String status;
  final bool isPresent;

  const _HistoryItem({
    required this.date,
    required this.subject,
    required this.time,
    required this.status,
    required this.isPresent,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DSCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isPresent ? colors.success : colors.danger).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPresent ? Icons.check_circle : Icons.cancel,
              color: isPresent ? colors.success : colors.danger,
              size: 24,
            ),
          ),
          const SizedBox(width: SpacingTokens.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(
                  subject,
                  role: TypographyRole.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Insets.spaceVertical4,
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: colors.textSecondary),
                    const SizedBox(width: SpacingTokens.space4),
                    DSText(
                      '$date • $time',
                      role: TypographyRole.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
          DSBadge(
            label: status,
            variant: isPresent ? DSBadgeVariant.success : DSBadgeVariant.danger,
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final String title;
  final String content;
  final String date;
  final String category;

  const _PostCard({
    required this.title,
    required this.content,
    required this.date,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DSText(
                  title,
                  role: TypographyRole.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DSBadge(
                label: category,
                variant: DSBadgeVariant.secondary,
              ),
            ],
          ),
          Insets.spaceVertical8,
          DSText(
            content,
            role: TypographyRole.body,
          ),
          Insets.spaceVertical12,
          DSText(
            date,
            role: TypographyRole.caption,
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
