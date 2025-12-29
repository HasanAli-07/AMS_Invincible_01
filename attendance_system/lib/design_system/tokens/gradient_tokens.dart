import 'package:flutter/widgets.dart';

import 'color_tokens.dart';
import 'opacity_tokens.dart';

/// Gradient tokens for brand surfaces and glass effects.
class GradientTokens {
  GradientTokens._();

  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      ColorPrimitives.brandBlue500,
      ColorPrimitives.accentPurple500,
    ],
  );

  static const Gradient accentGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      ColorPrimitives.accentPurple500,
      ColorPrimitives.brandBlue700,
    ],
  );

  static const Gradient glassBorderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      ColorPrimitives.neutralWhite,
      ColorPrimitives.neutralWhite,
      ColorPrimitives.neutralWhite,
    ],
    stops: [0, 0.5, 1],
  );
}

/// Helper to build a glassmorphism-style background color.
class GlassTokens {
  GlassTokens._();

  static Color glassBackground(Color base) =>
      base.withOpacity(OpacityTokens.glassBackgroundOpacity);
}


