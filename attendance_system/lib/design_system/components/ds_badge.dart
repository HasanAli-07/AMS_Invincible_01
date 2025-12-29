import 'package:flutter/material.dart';

import '../tokens/color_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/typography_tokens.dart';
import 'ds_text.dart';

/// Badge/Pill component for tags like PRIMARY, BACKUP, NEW, etc.
class DSBadge extends StatelessWidget {
  final String label;
  final DSBadgeVariant variant;

  const DSBadge({
    super.key,
    required this.label,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Color backgroundColor;
    Color textColor;

    switch (variant) {
      case DSBadgeVariant.primary:
        backgroundColor = colors.accentPrimary.withOpacity(0.1);
        textColor = colors.accentPrimary;
        break;
      case DSBadgeVariant.success:
        backgroundColor = colors.success.withOpacity(0.1);
        textColor = colors.success;
        break;
      case DSBadgeVariant.warning:
        backgroundColor = colors.warning.withOpacity(0.1);
        textColor = colors.warning;
        break;
      case DSBadgeVariant.danger:
        backgroundColor = colors.danger.withOpacity(0.1);
        textColor = colors.danger;
        break;
      case DSBadgeVariant.secondary:
        backgroundColor = colors.backgroundElevated;
        textColor = colors.textSecondary;
        break;
      case DSBadgeVariant.info:
        backgroundColor = colors.accentSecondary.withOpacity(0.1);
        textColor = colors.accentSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.space8,
        vertical: SpacingTokens.space4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: RadiusTokens.pillSmall,
      ),
      child: DSText(
        label,
        role: TypographyRole.caption,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

enum DSBadgeVariant {
  primary,
  success,
  warning,
  danger,
  secondary,
  info,
}

