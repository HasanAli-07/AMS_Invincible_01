import 'package:flutter/material.dart';

import '../../design_system/components/ds_app_bar.dart';
import '../../design_system/components/ds_text.dart';
import '../../design_system/components/ds_card.dart';
import '../../design_system/components/ds_button.dart';
import '../../design_system/components/ds_badge.dart';
import '../../design_system/tokens/typography_tokens.dart';
import '../../design_system/tokens/spacing_tokens.dart';
import '../../design_system/tokens/color_tokens.dart';
import '../../design_system/tokens/radius_tokens.dart';

/// Attendance History Screen matching demo screen3.png
class AttendanceHistoryScreen extends StatelessWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: DSAppBar(
        name: 'Dr. A. Smith',
        department: 'Computer Science Dept.',
        notificationCount: 1,
      ),
      body: SingleChildScrollView(
        padding: Insets.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter Pills - Scrollable to prevent overflow
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterPill(
                    label: 'Semester: Fall 2023',
                    isSelected: true,
                    onTap: () {},
                  ),
                  const SizedBox(width: SpacingTokens.space8),
                  _FilterPill(
                    label: 'Subject: All',
                    isSelected: false,
                    onTap: () {},
                  ),
                  const SizedBox(width: SpacingTokens.space8),
                  _FilterPill(
                    label: 'Date',
                    isSelected: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),
            Insets.spaceVertical24,
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _SummaryStatCard(
                    icon: Icons.bookmark_outlined,
                    label: 'CLASSES TAKEN',
                    value: '42',
                  ),
                ),
                const SizedBox(width: SpacingTokens.space12),
                Expanded(
                  child: _SummaryStatCard(
                    icon: Icons.percent,
                    label: 'AVG. ATTENDANCE',
                    value: '85%',
                    subtitle: '+2%',
                    isPositive: true,
                  ),
                ),
              ],
            ),
            Insets.spaceVertical32,
            // THIS WEEK Section
            DSText(
              'THIS WEEK',
              role: TypographyRole.caption,
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            Insets.spaceVertical16,
            _ClassCard(
              courseTitle: 'Data Structures (CS202)',
              time: 'Today • 10:00 AM - 11:30 AM',
              attendance: '52 / 60',
              status: 'Editable (2h left)',
              statusVariant: DSBadgeVariant.warning,
              hasBorder: true,
            ),
            Insets.spaceVertical32,
            // EARLIER IN OCTOBER Section
            DSText(
              'EARLIER IN OCTOBER',
              role: TypographyRole.caption,
              style: TextStyle(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            Insets.spaceVertical16,
            _ClassCard(
              courseTitle: 'Database Systems (CS301)',
              time: 'Oct 23 • 02:00 PM - 03:30 PM',
              attendance: '45 / 58 Present',
              status: 'Confirmed',
              statusVariant: DSBadgeVariant.success,
              showAvatars: true,
            ),
            Insets.spaceVertical12,
            _ClassCard(
              courseTitle: 'Data Structures (CS202)',
              time: 'Oct 22 • 10:00 AM - 11:30 AM',
              attendance: '57 / 60',
              status: 'Confirmed',
              statusVariant: DSBadgeVariant.success,
              showProgressBar: true,
            ),
            Insets.spaceVertical12,
            _ClassCard(
              courseTitle: 'Intro to AI (CS401)',
              time: 'Oct 20 • 09:00 AM - 10:30 AM',
              attendance: '12 / 40 Present',
              status: 'Confirmed',
              statusVariant: DSBadgeVariant.success,
              showWarning: true,
            ),
            Insets.spaceVertical32,
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: RadiusTokens.pillSmall,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.space16,
          vertical: SpacingTokens.space8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.accentPrimary : colors.backgroundSurface,
          borderRadius: RadiusTokens.pillSmall,
          border: Border.all(
            color: isSelected ? colors.accentPrimary : colors.borderSubtle,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DSText(
              label,
              role: TypographyRole.body,
              style: TextStyle(
                color: isSelected ? Colors.white : colors.textPrimary,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: SpacingTokens.space4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final bool isPositive;

  const _SummaryStatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.isPositive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.space16),
      decoration: BoxDecoration(
        color: colors.backgroundSurface,
        borderRadius: RadiusTokens.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.accentPrimary, size: 24),
          Insets.spaceVertical12,
          DSText(
            label,
            role: TypographyRole.caption,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              fontSize: 11,
            ),
          ),
          Insets.spaceVertical8,
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: DSText(
                  value,
                  role: TypographyRole.displayLarge,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                  maxLines: 1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: SpacingTokens.space4),
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: isPositive ? colors.success : colors.danger,
                ),
                Flexible(
                  child: DSText(
                    subtitle!,
                    role: TypographyRole.caption,
                    style: TextStyle(
                      color: isPositive ? colors.success : colors.danger,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final String courseTitle;
  final String time;
  final String attendance;
  final String status;
  final DSBadgeVariant statusVariant;
  final bool hasBorder;
  final bool showAvatars;
  final bool showProgressBar;
  final bool showWarning;

  const _ClassCard({
    required this.courseTitle,
    required this.time,
    required this.attendance,
    required this.status,
    required this.statusVariant,
    this.hasBorder = false,
    this.showAvatars = false,
    this.showProgressBar = false,
    this.showWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(bottom: SpacingTokens.space12),
      padding: const EdgeInsets.all(SpacingTokens.space16),
      decoration: BoxDecoration(
        color: colors.backgroundSurface,
        borderRadius: RadiusTokens.card,
        border: hasBorder
            ? Border(left: BorderSide(color: colors.warning, width: 4))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: SpacingTokens.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Expanded(
                child: DSText(
                  courseTitle,
                  role: TypographyRole.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                ),
              ),
              DSBadge(label: status, variant: statusVariant),
            ],
          ),
          Insets.spaceVertical8,
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: colors.textSecondary),
              const SizedBox(width: SpacingTokens.space4),
              DSText(
                time,
                role: TypographyRole.caption,
              ),
            ],
          ),
          Insets.spaceVertical12,
          if (showAvatars)
            Row(
              children: [
                ...List.generate(3, (index) {
                  return Container(
                    margin: EdgeInsets.only(
                      right: index < 2 ? -SpacingTokens.space8 : 0,
                    ),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.accentPrimary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.backgroundSurface, width: 2),
                    ),
                    child: Center(
                      child: DSText(
                        ['JI', 'A', 'mk'][index],
                        role: TypographyRole.caption,
                        style: TextStyle(
                          color: colors.accentPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: SpacingTokens.space8),
                DSText(
                  attendance,
                  role: TypographyRole.body,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            )
          else if (showProgressBar)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.accentPrimary.withOpacity(0.2),
                    borderRadius: RadiusTokens.pillSmall,
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 0.95,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.accentPrimary,
                        borderRadius: RadiusTokens.pillSmall,
                      ),
                    ),
                  ),
                ),
                Insets.spaceVertical8,
                DSText(
                  attendance,
                  role: TypographyRole.body,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            )
          else if (showWarning)
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: colors.warning, size: 20),
                const SizedBox(width: SpacingTokens.space8),
                DSText(
                  attendance,
                  role: TypographyRole.body,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            )
          else
            DSText(
              attendance,
              role: TypographyRole.body,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          Insets.spaceVertical12,
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 300;
              return isSmall
                  ? Column(
                      children: [
                        if (hasBorder)
                          DSButton(
                            label: 'Edit',
                            onPressed: () {},
                            variant: DSButtonVariant.secondary,
                            icon: Icons.edit,
                            isSmall: true,
                          ),
                        if (hasBorder) Insets.spaceVertical8,
                        DSButton(
                          label: hasBorder ? 'View Details >' : 'Details >',
                          onPressed: () {},
                          isSmall: true,
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        if (hasBorder)
                          Expanded(
                            child: DSButton(
                              label: 'Edit',
                              onPressed: () {},
                              variant: DSButtonVariant.secondary,
                              icon: Icons.edit,
                              isSmall: true,
                              fullWidth: false,
                            ),
                          ),
                        if (hasBorder) const SizedBox(width: SpacingTokens.space8),
                        Expanded(
                          flex: hasBorder ? 2 : 1,
                          child: DSButton(
                            label: hasBorder ? 'View Details >' : 'Details >',
                            onPressed: () {},
                            fullWidth: false,
                            isSmall: true,
                          ),
                        ),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }
}

