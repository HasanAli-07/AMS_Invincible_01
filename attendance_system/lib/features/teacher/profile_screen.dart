import 'package:flutter/material.dart';

import '../../design_system/components/ds_app_bar.dart';
import '../../design_system/components/ds_text.dart';
import '../../design_system/components/ds_card.dart';
import '../../design_system/components/ds_button.dart';
import '../../design_system/components/ds_badge.dart';
import '../../design_system/components/ds_bottom_nav.dart';
import '../../design_system/tokens/typography_tokens.dart';
import '../../design_system/tokens/spacing_tokens.dart';
import '../../design_system/tokens/color_tokens.dart';
import '../../design_system/tokens/radius_tokens.dart';
import '../auth/auth_routes.dart';

/// Profile Screen matching demo screen6.png
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: DSAppBar(
        name: 'Dr. Sarah Mitchell',
        department: 'Computer Science & Engineering',
        notificationCount: 1,
        onLogoutTap: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AuthRoutes.login,
            (route) => false,
          );
        },
      ),
      body: SingleChildScrollView(
        padding: Insets.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Card
            DSCard(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: colors.accentPrimary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: colors.accentPrimary,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Insets.spaceVertical16,
                  DSText(
                    'Dr. Sarah Mitchell',
                    role: TypographyRole.displayLarge,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Insets.spaceVertical8,
                  DSText(
                    'Computer Science & Engineering',
                    role: TypographyRole.body,
                    style: TextStyle(color: colors.textSecondary),
                  ),
                  Insets.spaceVertical12,
                  DSBadge(
                    label: 'ID: FAC-9921',
                    variant: DSBadgeVariant.secondary,
                  ),
                  Insets.spaceVertical24,
                  DSButton(
                    label: 'Connect via WhatsApp Assistant',
                    onPressed: () {},
                    icon: Icons.chat,
                  ),
                ],
              ),
            ),
            Insets.spaceVertical24,
            // Academic Load Section
            _SectionCard(
              icon: Icons.school_outlined,
              title: 'Academic Load',
              children: [
                _ListItem(
                  title: 'CS101 - Intro to Algorithms',
                  subtitle: 'Mon, Wed, Fri • 10:00 AM',
                  badge: 'Sem 3',
                  badgeColor: colors.accentPrimary,
                ),
                Insets.spaceVertical12,
                _ListItem(
                  title: 'CS405 - Database Management',
                  subtitle: 'Tue, Thu • 02:00 PM',
                  badge: 'Sem 5',
                  badgeColor: colors.accentSecondary,
                ),
              ],
            ),
            Insets.spaceVertical16,
            // Contact Details Section
            _SectionCard(
              icon: Icons.person_outline,
              title: 'Contact Details',
              children: [
                _ContactItem(
                  icon: Icons.email_outlined,
                  label: 'Email Address',
                  value: 'sarah.m@college.edu',
                ),
                Insets.spaceVertical12,
                _ContactItem(
                  icon: Icons.phone_outlined,
                  label: 'Phone Number',
                  value: '+1 555-0123-456',
                ),
                Insets.spaceVertical12,
                _ContactItem(
                  icon: Icons.location_on_outlined,
                  label: 'Office Location',
                  value: 'Room 304, Block B',
                ),
              ],
            ),
            Insets.spaceVertical16,
            // Settings Section
            _SectionCard(
              icon: Icons.settings_outlined,
              title: 'Settings',
              children: [
                _SettingsItem(
                  title: 'Change Password',
                  onTap: () {},
                ),
                Insets.spaceVertical12,
                _SettingsItem(
                  title: 'Notifications',
                  isToggle: true,
                  toggleValue: true,
                  onTap: () {},
                ),
                Insets.spaceVertical12,
                _SettingsItem(
                  title: 'Privacy Policy',
                  onTap: () {},
                ),
                Insets.spaceVertical12,
                _SettingsItem(
                  title: 'Help & Support',
                  onTap: () {},
                ),
              ],
            ),
            Insets.spaceVertical32,
          ],
        ),
      ),
      // No bottom nav on profile screen to avoid duplicates
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
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
              Icon(icon, color: colors.accentPrimary, size: 20),
              const SizedBox(width: SpacingTokens.space8),
              DSText(
                title,
                role: TypographyRole.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Insets.spaceVertical16,
          ...children,
        ],
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;

  const _ListItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
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
                subtitle,
                role: TypographyRole.caption,
              ),
            ],
          ),
        ),
        DSBadge(
          label: badge,
          variant: badgeColor == colors.accentPrimary
              ? DSBadgeVariant.primary
              : DSBadgeVariant.info,
        ),
      ],
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.backgroundElevated,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: colors.textSecondary),
        ),
        const SizedBox(width: SpacingTokens.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DSText(
                label,
                role: TypographyRole.caption,
                style: TextStyle(color: colors.textSecondary),
              ),
              Insets.spaceVertical4,
              DSText(
                value,
                role: TypographyRole.body,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final String title;
  final bool isToggle;
  final bool toggleValue;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.title,
    this.isToggle = false,
    this.toggleValue = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: DSText(
              title,
              role: TypographyRole.body,
            ),
          ),
          if (isToggle)
            Switch(
              value: toggleValue,
              onChanged: (value) {},
              activeColor: colors.accentPrimary,
            )
          else
            Icon(Icons.arrow_forward_ios, size: 16, color: colors.textSecondary),
        ],
      ),
    );
  }
}

