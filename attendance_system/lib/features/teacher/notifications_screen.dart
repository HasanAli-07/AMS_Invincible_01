import 'package:flutter/material.dart';

import '../../design_system/components/ds_app_bar.dart';
import '../../design_system/components/ds_text.dart';
import '../../design_system/components/ds_card.dart';
import '../../design_system/components/ds_badge.dart';
import '../../design_system/tokens/typography_tokens.dart';
import '../../design_system/tokens/spacing_tokens.dart';
import '../../design_system/tokens/color_tokens.dart';
import '../../design_system/tokens/radius_tokens.dart';

/// Notifications Screen matching demo screen5.png
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: DSAppBar(
        name: 'Prof. John Doe',
        department: 'CS Department',
        notificationCount: 0,
      ),
      body: Column(
        children: [
          // Filter Pills
          Container(
            padding: Insets.screenPadding,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'All', isSelected: true, onTap: () {}),
                  const SizedBox(width: SpacingTokens.space8),
                  _FilterChip(label: 'Institute', isSelected: false, onTap: () {}),
                  const SizedBox(width: SpacingTokens.space8),
                  _FilterChip(label: 'Department', isSelected: false, onTap: () {}),
                  const SizedBox(width: SpacingTokens.space8),
                  _FilterChip(label: 'Placement', isSelected: false, onTap: () {}),
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: Insets.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _NotificationSection(
                    title: 'TODAY',
                    notifications: [
                      _NotificationData(
                        title: 'Final Exam Schedule Released',
                        description:
                            'The final examination schedule for the Fall 2023 semester has been finalized and attached...',
                        time: '2h ago',
                        category: 'INSTITUTE',
                        isNew: true,
                      ),
                      _NotificationData(
                        title: 'Department Meeting Rescheduled',
                        description:
                            'Due to the Dean\'s unexpected visit, the monthly department meeting scheduled for 2:00 PM...',
                        time: '5h ago',
                        category: 'DEPT',
                        isNew: true,
                      ),
                    ],
                  ),
                  Insets.spaceVertical32,
                  _NotificationSection(
                    title: 'YESTERDAY',
                    notifications: [
                      _NotificationData(
                        title: 'Campus Maintenance Alert',
                        description:
                            'Scheduled power maintenance will occur in the North Wing this Saturday. Please ensure all la...',
                        time: 'Yesterday, 4:30 PM',
                        category: 'INSTITUTE',
                        isNew: false,
                      ),
                      _NotificationData(
                        title: 'Infosys Recruitment Drive',
                        description:
                            'The upcoming placement drive for final year students begins next week. Faculty...',
                        time: 'Yesterday, 10:00 AM',
                        category: 'PLACEMENT',
                        isNew: false,
                        hasAttachment: true,
                        attachmentName: 'Guidelines.pdf',
                      ),
                    ],
                  ),
                  Insets.spaceVertical32,
                  _NotificationSection(
                    title: 'EARLIER',
                    notifications: [
                      _NotificationData(
                        title: 'Annual Convocation 2023',
                        description:
                            'Highlights from the convocation ceremony held last week. Congratulations to all graduating...',
                        time: 'Oct 24, 2023',
                        category: 'EVENT',
                        isNew: false,
                        hasImage: true,
                      ),
                    ],
                  ),
                  Insets.spaceVertical32,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
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
          color: isSelected ? colors.accentPrimary : Colors.transparent,
          borderRadius: RadiusTokens.pillSmall,
          border: Border.all(
            color: isSelected ? colors.accentPrimary : colors.borderSubtle,
          ),
        ),
        child: DSText(
          label,
          role: TypographyRole.body,
          style: TextStyle(
            color: isSelected ? Colors.white : colors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _NotificationSection extends StatelessWidget {
  final String title;
  final List<_NotificationData> notifications;

  const _NotificationSection({
    required this.title,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DSText(
          title,
          role: TypographyRole.caption,
          style: TextStyle(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        Insets.spaceVertical16,
        ...notifications.map((notification) => Padding(
              padding: const EdgeInsets.only(bottom: SpacingTokens.space12),
              child: _NotificationCard(notification: notification),
            )),
      ],
    );
  }
}

class _NotificationData {
  final String title;
  final String description;
  final String time;
  final String category;
  final bool isNew;
  final bool hasAttachment;
  final String? attachmentName;
  final bool hasImage;

  _NotificationData({
    required this.title,
    required this.description,
    required this.time,
    required this.category,
    this.isNew = false,
    this.hasAttachment = false,
    this.attachmentName,
    this.hasImage = false,
  });
}

class _NotificationCard extends StatelessWidget {
  final _NotificationData notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundSurface,
        borderRadius: RadiusTokens.card,
        border: notification.isNew
            ? Border(left: BorderSide(color: colors.accentPrimary, width: 4))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notification.hasImage)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.backgroundElevated,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(RadiusTokens.radiusLarge),
                  topRight: Radius.circular(RadiusTokens.radiusLarge),
                ),
              ),
              child: Icon(Icons.image, size: 48, color: colors.textSecondary),
            ),
          Padding(
            padding: const EdgeInsets.all(SpacingTokens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (notification.isNew) ...[
                      const DSBadge(label: 'NEW', variant: DSBadgeVariant.primary),
                      const SizedBox(width: SpacingTokens.space8),
                    ],
                    Icon(Icons.access_time, size: 14, color: colors.textSecondary),
                    const SizedBox(width: SpacingTokens.space4),
                    DSText(
                      notification.time,
                      role: TypographyRole.caption,
                    ),
                    const Spacer(),
                    DSBadge(
                      label: notification.category,
                      variant: DSBadgeVariant.secondary,
                    ),
                  ],
                ),
                Insets.spaceVertical12,
                DSText(
                  notification.title,
                  role: TypographyRole.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Insets.spaceVertical8,
                DSText(
                  notification.description,
                  role: TypographyRole.body,
                ),
                if (notification.hasAttachment) ...[
                  Insets.spaceVertical12,
                  Container(
                    padding: const EdgeInsets.all(SpacingTokens.space12),
                    decoration: BoxDecoration(
                      color: colors.backgroundElevated,
                      borderRadius: RadiusTokens.button,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: colors.danger, size: 20),
                        const SizedBox(width: SpacingTokens.space8),
                        DSText(
                          notification.attachmentName!,
                          role: TypographyRole.body,
                          style: TextStyle(color: colors.danger),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

