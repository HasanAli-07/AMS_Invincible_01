import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../tokens/color_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/typography_tokens.dart';
import 'ds_text.dart';

/// Enhanced App Bar with Logo, Name, Designation, Notification, and Profile
class DSAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final String department;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogoutTap;
  final int? notificationCount;
  final String? profileImageUrl;

  const DSAppBar({
    super.key,
    required this.name,
    required this.department,
    this.onNotificationTap,
    this.onProfileTap,
    this.onLogoutTap,
    this.notificationCount,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: colors.backgroundSurface,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: SpacingTokens.space16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AppLogo(isDark: isDark),
            const SizedBox(width: SpacingTokens.space12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DSText(
                    name,
                    role: TypographyRole.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  DSText(
                    department,
                    role: TypographyRole.caption,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      leadingWidth: 200, // Increased to accommodate logo + spacing + text
      titleSpacing: 0,
      actions: [
        // Notification Icon with Badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: colors.textPrimary,
                size: 24,
              ),
              onPressed: onNotificationTap ?? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications')),
                );
              },
            ),
            if (notificationCount != null && notificationCount! > 0)
              Positioned(
                right: 6,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.danger,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.backgroundSurface,
                      width: 2,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      notificationCount! > 9 ? '9+' : '${notificationCount}',
                      style: TextStyle(
                        color: colors.textOnAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Profile Icon/Avatar with Dropdown Menu
        Padding(
          padding: const EdgeInsets.only(right: SpacingTokens.space8),
          child: PopupMenuButton<String>(
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: RadiusTokens.card,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SpacingTokens.space8,
                vertical: SpacingTokens.space4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: colors.accentPrimary.withOpacity(0.1),
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : null,
                    child: profileImageUrl == null
                        ? Text(
                            name.isNotEmpty
                                ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: colors.accentPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: SpacingTokens.space4),
                  Icon(
                    Icons.arrow_drop_down,
                    color: colors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
            onSelected: (value) {
              if (value == 'profile' && onProfileTap != null) {
                onProfileTap!();
              } else if (value == 'logout' && onLogoutTap != null) {
                onLogoutTap!();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 20, color: colors.textPrimary),
                    const SizedBox(width: SpacingTokens.space12),
                    DSText('Profile', role: TypographyRole.body),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: colors.danger),
                    const SizedBox(width: SpacingTokens.space12),
                    DSText(
                      'Logout',
                      role: TypographyRole.body,
                      style: TextStyle(color: colors.danger),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// App Logo Widget - Uses SVG logo from assets
/// App bar uses backgroundSurface, so we match logos accordingly:
/// - Light theme: white background -> "light theme primary.svg"
/// - Dark theme: gray800 (#1F2933) background -> "Dark theme surface.svg"
class _AppLogo extends StatelessWidget {
  final bool isDark;

  const _AppLogo({required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Use appropriate logo based on theme and background surface
    final logoPath = isDark 
        ? 'Logos/Dark theme surface.svg'  // Matches gray800 (#1F2933) background
        : 'Logos/light theme primary.svg'; // Matches white background

    return SizedBox(
      width: 40,
      height: 40,
      child: SvgPicture.asset(
        logoPath,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.colors.accentPrimary.withOpacity(0.1),
            borderRadius: RadiusTokens.button,
          ),
          child: Icon(
            Icons.school,
            color: context.colors.accentPrimary,
            size: 24,
          ),
        ),
      ),
    );
  }
}
