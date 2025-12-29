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

/// Enhanced Attendance Confirmation Screen - No duplicates, proper layout
class AttendanceConfirmScreen extends StatelessWidget {
  const AttendanceConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: DSAppBar(
        name: 'Prof. A. Smith',
        department: 'Dept. of CS',
        notificationCount: 1,
      ),
      body: SingleChildScrollView(
        padding: Insets.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Course Info Card (Blue Background)
            Container(
              padding: const EdgeInsets.all(SpacingTokens.space24),
              decoration: BoxDecoration(
                color: colors.accentPrimary,
                borderRadius: RadiusTokens.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DSText(
                    'CS101: Data Structures',
                    role: TypographyRole.displayLarge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Insets.spaceVertical8,
                  DSText(
                    'Section A • B.Tech CS-II',
                    role: TypographyRole.body,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Insets.spaceVertical16,
                  // Responsive time/date row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmall = constraints.maxWidth < 350;
                      return isSmall
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, color: Colors.white70, size: 18),
                                    const SizedBox(width: SpacingTokens.space8),
                                    DSText(
                                      '09:00 AM - 10:00 AM',
                                      role: TypographyRole.body,
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                                Insets.spaceVertical8,
                                Row(
                                  children: [
                                    DSText(
                                      'Oct 24, 2023',
                                      role: TypographyRole.body,
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.calendar_today, color: Colors.white70, size: 18),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                const Icon(Icons.access_time, color: Colors.white70, size: 18),
                                const SizedBox(width: SpacingTokens.space8),
                                DSText(
                                  '09:00 AM - 10:00 AM',
                                  role: TypographyRole.body,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(width: SpacingTokens.space16),
                                DSText(
                                  'Oct 24, 2023',
                                  role: TypographyRole.body,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const Spacer(),
                                const Icon(Icons.calendar_today, color: Colors.white70, size: 18),
                              ],
                            );
                    },
                  ),
                ],
              ),
            ),
            Insets.spaceVertical24,
            // Attendance Summary Cards - Horizontal, Equal Width
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'TOTAL',
                    value: '60',
                    borderColor: null,
                  ),
                ),
                const SizedBox(width: SpacingTokens.space12),
                Expanded(
                  child: _SummaryCard(
                    label: 'PRESENT',
                    value: '52',
                    borderColor: colors.success,
                  ),
                ),
                const SizedBox(width: SpacingTokens.space12),
                Expanded(
                  child: _SummaryCard(
                    label: 'ABSENT',
                    value: '08',
                    borderColor: colors.danger,
                  ),
                ),
              ],
            ),
            Insets.spaceVertical24,
            // Student List Header - Responsive
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 350;
                return isSmall
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DSText(
                            'Student List',
                            role: TypographyRole.headline,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Insets.spaceVertical8,
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: colors.textSecondary),
                              const SizedBox(width: SpacingTokens.space4),
                              DSText(
                                'Confidence Level',
                                role: TypographyRole.caption,
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          DSText(
                            'Student List',
                            role: TypographyRole.headline,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Icon(Icons.info_outline, size: 16, color: colors.textSecondary),
                          const SizedBox(width: SpacingTokens.space4),
                          DSText(
                            'Confidence Level',
                            role: TypographyRole.caption,
                          ),
                        ],
                      );
              },
            ),
            Insets.spaceVertical16,
            // Student List
            ..._generateStudentList(),
            Insets.spaceVertical24,
            // Warning Message
            Container(
              padding: const EdgeInsets.all(SpacingTokens.space12),
              decoration: BoxDecoration(
                color: colors.warning.withOpacity(0.1),
                borderRadius: RadiusTokens.button,
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: colors.warning, size: 20),
                  const SizedBox(width: SpacingTokens.space8),
                  Expanded(
                    child: DSText(
                      'Attendance will be saved only after confirmation.',
                      role: TypographyRole.body,
                      style: TextStyle(color: colors.warning),
                    ),
                  ),
                ],
              ),
            ),
            Insets.spaceVertical24,
            // Action Buttons - Responsive
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 400;
                return isSmall
                    ? Column(
                        children: [
                          DSButton(
                            label: 'CONFIRM',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Attendance confirmed!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context);
                            },
                            icon: Icons.check,
                          ),
                          Insets.spaceVertical12,
                          Row(
                            children: [
                              Expanded(
                                child: DSButton(
                                  label: 'Reject',
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  variant: DSButtonVariant.danger,
                                  icon: Icons.close,
                                ),
                              ),
                              const SizedBox(width: SpacingTokens.space12),
                              Expanded(
                                child: DSButton(
                                  label: 'Edit',
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Edit mode activated')),
                                    );
                                  },
                                  variant: DSButtonVariant.secondary,
                                  icon: Icons.edit,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: DSButton(
                              label: 'Reject',
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              variant: DSButtonVariant.danger,
                              icon: Icons.close,
                            ),
                          ),
                          const SizedBox(width: SpacingTokens.space12),
                          Expanded(
                            child: DSButton(
                              label: 'Edit',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Edit mode activated')),
                                );
                              },
                              variant: DSButtonVariant.secondary,
                              icon: Icons.edit,
                            ),
                          ),
                          const SizedBox(width: SpacingTokens.space12),
                          Expanded(
                            flex: 2,
                            child: DSButton(
                              label: 'CONFIRM',
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Attendance confirmed!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                Navigator.pop(context);
                              },
                              icon: Icons.check,
                            ),
                          ),
                        ],
                      );
              },
            ),
            Insets.spaceVertical32,
          ],
        ),
      ),
    );
  }

  List<Widget> _generateStudentList() {
    final students = [
      {'id': '101', 'name': 'John Doe', 'confidence': 'High Confidence', 'present': true, 'needsVerify': false},
      {'id': '102', 'name': 'Alice Johnson', 'confidence': 'High Confidence', 'present': true, 'needsVerify': false},
      {'id': '103', 'name': 'Robert Smith', 'confidence': 'Verify Status', 'present': false, 'needsVerify': true},
      {'id': '104', 'name': 'Emily Davis', 'confidence': 'High Confidence', 'present': true, 'needsVerify': false},
      {'id': '105', 'name': 'Michael Brown', 'confidence': 'High Confidence', 'present': true, 'needsVerify': false},
      {'id': '106', 'name': 'Sarah Wilson', 'confidence': 'Verify Status', 'present': false, 'needsVerify': true},
    ];

    return students.map((student) {
      return Padding(
        padding: const EdgeInsets.only(bottom: SpacingTokens.space12),
        child: _StudentCard(
          id: student['id'] as String,
          name: student['name'] as String,
          confidence: student['confidence'] as String,
          isPresent: student['present'] as bool,
          needsVerify: student['needsVerify'] as bool,
        ),
      );
    }).toList();
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? borderColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.space16),
      decoration: BoxDecoration(
        color: colors.backgroundSurface,
        borderRadius: RadiusTokens.card,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 3)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DSText(
            label,
            role: TypographyRole.caption,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          Insets.spaceVertical8,
          DSText(
            value,
            role: TypographyRole.displayLarge,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final String id;
  final String name;
  final String confidence;
  final bool isPresent;
  final bool needsVerify;

  const _StudentCard({
    required this.id,
    required this.name,
    required this.confidence,
    required this.isPresent,
    required this.needsVerify,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.space16),
      decoration: BoxDecoration(
        color: colors.backgroundSurface,
        borderRadius: RadiusTokens.card,
        border: needsVerify
            ? Border(left: BorderSide(color: colors.warning, width: 4))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.accentPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: DSText(
                id,
                role: TypographyRole.caption,
                style: TextStyle(
                  color: colors.accentPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: SpacingTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(
                  name,
                  role: TypographyRole.body,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                ),
                Insets.spaceVertical4,
                Wrap(
                  spacing: SpacingTokens.space4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 14,
                      color: needsVerify ? colors.warning : colors.accentPrimary,
                    ),
                    Flexible(
                      child: DSText(
                        confidence,
                        role: TypographyRole.caption,
                        style: TextStyle(
                          color: needsVerify ? colors.warning : colors.textSecondary,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: SpacingTokens.space8),
          DSButton(
            label: isPresent ? 'Present' : 'Absent',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${isPresent ? "Present" : "Absent"} status toggled'),
                ),
              );
            },
            variant: isPresent ? DSButtonVariant.success : DSButtonVariant.danger,
            isSmall: true,
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}
