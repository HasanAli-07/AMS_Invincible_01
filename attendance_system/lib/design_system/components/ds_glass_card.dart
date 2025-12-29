import 'dart:ui';

import 'package:flutter/material.dart';

import '../tokens/color_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/elevation_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/opacity_tokens.dart';

/// Glassmorphic card component with backdrop blur and semi-transparent background.
class DSGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const DSGlassCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ClipRRect(
      borderRadius: RadiusTokens.card,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: ElevationTokens.glassBlurStrength,
          sigmaY: ElevationTokens.glassBlurStrength,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.backgroundSurface.withOpacity(
              OpacityTokens.glassBackgroundOpacity,
            ),
            borderRadius: RadiusTokens.card,
            border: Border.all(
              color: colors.borderSubtle.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.backgroundElevated.withOpacity(
                  OpacityTokens.opacityOverlaySoft,
                ),
                blurRadius: ElevationTokens.elevationMedium,
                offset: const Offset(0, ElevationTokens.elevationLow),
              ),
            ],
          ),
          padding: padding ?? Insets.cardPadding,
          child: child,
        ),
      ),
    );
  }
}

