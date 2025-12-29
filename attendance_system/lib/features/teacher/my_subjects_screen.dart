import 'package:flutter/material.dart';

import '../../design_system/components/ds_app_bar.dart';
import '../../design_system/components/ds_text.dart';
import '../../design_system/components/ds_card.dart';
import '../../design_system/components/ds_badge.dart';
import '../../design_system/tokens/typography_tokens.dart';
import '../../design_system/tokens/spacing_tokens.dart';
import '../../design_system/tokens/color_tokens.dart';
import '../../design_system/tokens/radius_tokens.dart';

/// Enhanced My Subjects Screen with proper timeline
class MySubjectsScreen extends StatefulWidget {
  const MySubjectsScreen({super.key});

  @override
  State<MySubjectsScreen> createState() => _MySubjectsScreenState();
}

class _MySubjectsScreenState extends State<MySubjectsScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: DSAppBar(
        name: 'Prof. A. Smith',
        department: 'Computer Science Dept.',
      ),
      body: SingleChildScrollView(
        padding: Insets.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tabs - Responsive
            LayoutBuilder(
              builder: (context, constraints) {
                return constraints.maxWidth < 400
                    ? Column(
                        children: [
                          _TabButton(
                            label: 'My Subjects',
                            isSelected: _selectedTab == 0,
                            onTap: () => setState(() => _selectedTab = 0),
                          ),
                          const SizedBox(height: SpacingTokens.space8),
                          _TabButton(
                            label: 'Weekly Timetable',
                            isSelected: _selectedTab == 1,
                            onTap: () => setState(() => _selectedTab = 1),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _TabButton(
                              label: 'My Subjects',
                              isSelected: _selectedTab == 0,
                              onTap: () => setState(() => _selectedTab = 0),
                            ),
                          ),
                          const SizedBox(width: SpacingTokens.space8),
                          Expanded(
                            child: _TabButton(
                              label: 'Weekly Timetable',
                              isSelected: _selectedTab == 1,
                              onTap: () => setState(() => _selectedTab = 1),
                            ),
                          ),
                        ],
                      );
              },
            ),
            Insets.spaceVertical24,
            if (_selectedTab == 0) ...[
              // Summary Cards - Responsive
              LayoutBuilder(
                builder: (context, constraints) {
                  return constraints.maxWidth < 400
                      ? Column(
                          children: [
                            _SummaryCard(
                              icon: Icons.school_outlined,
                              iconColor: colors.accentPrimary,
                              value: '3',
                              label: 'Total Subjects',
                            ),
                            Insets.spaceVertical12,
                            _SummaryCard(
                              icon: Icons.access_time,
                              iconColor: colors.accentSecondary,
                              value: '12',
                              label: 'Hours/Week',
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: _SummaryCard(
                                icon: Icons.school_outlined,
                                iconColor: colors.accentPrimary,
                                value: '3',
                                label: 'Total Subjects',
                              ),
                            ),
                            const SizedBox(width: SpacingTokens.space12),
                            Expanded(
                              child: _SummaryCard(
                                icon: Icons.access_time,
                                iconColor: colors.accentSecondary,
                                value: '12',
                                label: 'Hours/Week',
                              ),
                            ),
                          ],
                        );
                },
              ),
              Insets.spaceVertical32,
              // Assigned Courses Header
              Wrap(
                spacing: SpacingTokens.space8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Flexible(
                    child: DSText(
                      'ASSIGNED COURSES',
                      role: TypographyRole.headline,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  DSText(
                    'Fall 2023',
                    role: TypographyRole.body,
                    style: TextStyle(color: colors.accentPrimary),
                  ),
                ],
              ),
              Insets.spaceVertical16,
              // Course Cards
              _CourseCard(
                icon: Icons.code,
                iconColor: colors.accentPrimary,
                courseTitle: 'Data Structures',
                courseCode: 'CS-201',
                semester: 'Sem 3',
                batch: 'Batch A',
                students: '45 Students',
                status: '• ACTIVE',
                statusColor: colors.success,
                actionLabel: 'View Attendance',
              ),
              Insets.spaceVertical12,
              _CourseCard(
                icon: Icons.memory,
                iconColor: colors.accentSecondary,
                courseTitle: 'Operating System',
                courseCode: 'CS-205',
                semester: 'Sem 5',
                batch: 'Batch B',
                students: '50 Students',
                status: 'MON 10 AM',
                statusColor: colors.warning,
                actionLabel: 'View Attendance',
              ),
              Insets.spaceVertical12,
              _CourseCard(
                icon: Icons.rocket_launch,
                iconColor: colors.warning,
                courseTitle: 'Final Year Project',
                courseCode: 'CS-400',
                semester: 'Sem 7',
                batch: 'All Batches',
                students: '12 Groups',
                actionLabel: 'Manage Groups',
              ),
              Insets.spaceVertical32,
              // Today's Schedule - Enhanced Timeline
              Wrap(
                spacing: SpacingTokens.space8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Flexible(
                    child: DSText(
                      'TODAY\'S SCHEDULE',
                      role: TypographyRole.headline,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  DSText(
                    'Monday, Oct 24',
                    role: TypographyRole.body,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ],
              ),
              Insets.spaceVertical16,
              _EnhancedScheduleTimeline(),
            ] else
              _WeeklyTimetableView(),
            Insets.spaceVertical32,
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: RadiusTokens.button,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.space12),
        decoration: BoxDecoration(
          color: isSelected ? colors.backgroundSurface : colors.backgroundElevated,
          borderRadius: RadiusTokens.button,
        ),
        child: Center(
          child: DSText(
            label,
            role: TypographyRole.body,
            style: TextStyle(
              color: isSelected ? colors.accentPrimary : colors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.space20),
      decoration: BoxDecoration(
        color: colors.accentPrimary.withOpacity(0.05),
        borderRadius: RadiusTokens.card,
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 32),
          Insets.spaceVertical12,
          DSText(
            value,
            role: TypographyRole.displayLarge,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Insets.spaceVertical4,
          DSText(
            label,
            role: TypographyRole.body,
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String courseTitle;
  final String courseCode;
  final String semester;
  final String batch;
  final String students;
  final String? status;
  final Color? statusColor;
  final String actionLabel;

  const _CourseCard({
    required this.icon,
    required this.iconColor,
    required this.courseTitle,
    required this.courseCode,
    required this.semester,
    required this.batch,
    required this.students,
    this.status,
    this.statusColor,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: RadiusTokens.button,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: SpacingTokens.space16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: SpacingTokens.space8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Flexible(
                          child: DSText(
                            courseTitle,
                            role: TypographyRole.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (status != null)
                          DSBadge(
                            label: status!,
                            variant: statusColor == colors.success
                                ? DSBadgeVariant.success
                                : statusColor == colors.warning
                                    ? DSBadgeVariant.warning
                                    : DSBadgeVariant.secondary,
                          ),
                      ],
                    ),
                    Insets.spaceVertical4,
                    DSText(
                      courseCode,
                      role: TypographyRole.body,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    Insets.spaceVertical8,
                    Wrap(
                      spacing: SpacingTokens.space12,
                      runSpacing: SpacingTokens.space8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.school_outlined, size: 14, color: colors.textSecondary),
                            const SizedBox(width: SpacingTokens.space4),
                            DSText(semester, role: TypographyRole.caption),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.group_outlined, size: 14, color: colors.textSecondary),
                            const SizedBox(width: SpacingTokens.space4),
                            Flexible(
                              child: DSText(batch, role: TypographyRole.caption, maxLines: 1),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline, size: 14, color: colors.textSecondary),
                            const SizedBox(width: SpacingTokens.space4),
                            Flexible(
                              child: DSText(students, role: TypographyRole.caption, maxLines: 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Insets.spaceVertical12,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        DSText(
                          actionLabel,
                          role: TypographyRole.body,
                          style: TextStyle(color: colors.accentPrimary),
                        ),
                        const SizedBox(width: SpacingTokens.space4),
                        Icon(Icons.arrow_forward_ios, size: 12, color: colors.accentPrimary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Enhanced Schedule Timeline with proper visual flow
class _EnhancedScheduleTimeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final now = DateTime.now();
    final scheduleItems = [
      _ScheduleItem(
        time: '09:00 AM',
        courseTitle: 'Data Structures',
        location: 'Room 301',
        duration: 90,
        isPast: false,
        isCurrent: true,
      ),
      _ScheduleItem(
        time: '11:00 AM',
        courseTitle: 'Operating Systems',
        location: 'Room 205',
        duration: 90,
        isPast: false,
        isCurrent: false,
      ),
      _ScheduleItem(
        time: '02:00 PM',
        courseTitle: 'Database Systems',
        location: 'Lab 101',
        duration: 120,
        isPast: false,
        isCurrent: false,
      ),
    ];

    return Column(
      children: [
        ...scheduleItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == scheduleItems.length - 1;
          return _ScheduleTimelineItem(
            item: item,
            isLast: isLast,
            hasNext: !isLast,
          );
        }),
      ],
    );
  }
}

class _ScheduleItem {
  final String time;
  final String courseTitle;
  final String location;
  final int duration;
  final bool isPast;
  final bool isCurrent;

  _ScheduleItem({
    required this.time,
    required this.courseTitle,
    required this.location,
    required this.duration,
    required this.isPast,
    required this.isCurrent,
  });
}

class _ScheduleTimelineItem extends StatelessWidget {
  final _ScheduleItem item;
  final bool isLast;
  final bool hasNext;

  const _ScheduleTimelineItem({
    required this.item,
    required this.isLast,
    required this.hasNext,
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
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: SpacingTokens.space4),
              child: DSText(
                item.time,
                role: TypographyRole.caption,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: item.isCurrent ? colors.accentPrimary : colors.textSecondary,
                ),
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: item.isCurrent
                    ? colors.accentPrimary
                    : item.isPast
                        ? colors.success
                        : colors.backgroundElevated,
                shape: BoxShape.circle,
                border: Border.all(
                  color: item.isCurrent
                      ? colors.accentPrimary
                      : item.isPast
                          ? colors.success
                          : colors.borderSubtle,
                  width: 2,
                ),
              ),
            ),
            if (hasNext)
              Container(
                width: 2,
                height: 80,
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
            padding: EdgeInsets.only(bottom: hasNext ? SpacingTokens.space16 : 0),
            child: DSCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DSText(
                          item.courseTitle,
                          role: TypographyRole.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (item.isCurrent)
                        DSBadge(
                          label: 'NOW',
                          variant: DSBadgeVariant.primary,
                        ),
                    ],
                  ),
                  Insets.spaceVertical8,
                  Wrap(
                    spacing: SpacingTokens.space12,
                    runSpacing: SpacingTokens.space8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.access_time, size: 14, color: colors.textSecondary),
                          const SizedBox(width: SpacingTokens.space4),
                          DSText(
                            '${item.duration} min',
                            role: TypographyRole.caption,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, size: 14, color: colors.textSecondary),
                          const SizedBox(width: SpacingTokens.space4),
                          Flexible(
                            child: DSText(
                              item.location,
                              role: TypographyRole.caption,
                              maxLines: 1,
                            ),
                          ),
                        ],
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

class _WeeklyTimetableView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: DSText('Weekly Timetable View', role: TypographyRole.headline),
    );
  }
}
