import 'package:flutter/material.dart';

import '../tokens/color_tokens.dart';
import '../tokens/radius_tokens.dart';
import '../tokens/elevation_tokens.dart';
import '../tokens/spacing_tokens.dart';

class DSCard extends StatelessWidget {
  final Widget child;

  const DSCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundSurface,
        borderRadius: RadiusTokens.card,
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: colors.backgroundElevated.withOpacity(0.08),
            blurRadius: ElevationTokens.elevationMedium,
            offset: const Offset(0, ElevationTokens.elevationLow),
          ),
        ],
      ),
      padding: Insets.cardPadding,
      child: child,
    );
  }
}


