import 'package:flutter/material.dart';

import '../tokens/color_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/opacity_tokens.dart';
import '../tokens/typography_tokens.dart';

enum DSButtonVariant {
  primary,
  secondary,
  danger,
  success,
}

class DSButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final DSButtonVariant variant;
  final bool fullWidth;
  final IconData? icon;
  final bool isSmall;

  const DSButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = DSButtonVariant.primary,
    this.fullWidth = true,
    this.icon,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyle = context.textStyle(TypographyRole.button);

    Color background;
    Color foreground;
    Color borderColor;

    switch (variant) {
      case DSButtonVariant.primary:
        background = colors.accentPrimary;
        foreground = colors.textOnAccent;
        borderColor = colors.accentPrimary;
        break;
      case DSButtonVariant.secondary:
        background = colors.backgroundSurface;
        foreground = colors.textPrimary;
        borderColor = colors.borderSubtle;
        break;
      case DSButtonVariant.danger:
        background = colors.danger;
        foreground = colors.textOnAccent;
        borderColor = colors.danger;
        break;
      case DSButtonVariant.success:
        background = colors.success;
        foreground = colors.textOnAccent;
        borderColor = colors.success;
        break;
    }

    final buttonChild = Padding(
      padding: isSmall
          ? const EdgeInsets.symmetric(
              horizontal: SpacingTokens.space12,
              vertical: SpacingTokens.space8,
            )
          : Insets.buttonPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: isSmall ? 16 : 18, color: foreground),
            const SizedBox(width: SpacingTokens.space8),
          ],
          Flexible(
            child: Text(
              label,
              style: textStyle.copyWith(
                color: foreground,
                fontSize: isSmall ? 12 : null,
              ),
            ),
          ),
        ],
      ),
    );

    final button = DecoratedBox(
      decoration: BoxDecoration(
        color: onPressed == null
            ? background.withOpacity(OpacityTokens.opacityDisabled)
            : background,
        borderRadius: RadiusTokens.button,
        border: Border.all(color: borderColor),
      ),
      child: buttonChild,
    );

    return Opacity(
      opacity: onPressed == null ? OpacityTokens.opacityDisabled : 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: fullWidth ? double.infinity : 0,
        ),
        child: InkWell(
          borderRadius: RadiusTokens.button,
          onTap: onPressed,
          child: button,
        ),
      ),
    );
  }
}


