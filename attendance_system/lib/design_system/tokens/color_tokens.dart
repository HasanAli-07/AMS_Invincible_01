import 'package:flutter/material.dart';

/// Primitive (non-semantic) brand palette.
/// These should NEVER be used directly in widgets.
class ColorPrimitives {
  ColorPrimitives._();

  // Brand blues
  static const Color brandBlue300 = Color(0xFF6EB6FF);
  static const Color brandBlue500 = Color(0xFF2F80ED);
  static const Color brandBlue700 = Color(0xFF1B4FA5);

  // Accent colors
  static const Color accentPurple500 = Color(0xFF9B51E0);
  static const Color accentGreen500 = Color(0xFF27AE60);
  static const Color accentRed500 = Color(0xFFEB5757);

  // Neutrals
  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color neutralBlack = Color(0xFF000000);

  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray800 = Color(0xFF1F2933);
  static const Color gray900 = Color(0xFF111827);
}

/// Semantic color tokens – these are what the UI should use.
/// Implemented as a ThemeExtension so they can vary per theme.
class SemanticColors extends ThemeExtension<SemanticColors> {
  final Color backgroundPrimary;
  final Color backgroundSurface;
  final Color backgroundElevated;

  final Color textPrimary;
  final Color textSecondary;
  final Color textOnAccent;

  final Color accentPrimary;
  final Color accentSecondary;

  final Color borderSubtle;
  final Color borderStrong;

  final Color danger;
  final Color success;
  final Color warning;

  const SemanticColors({
    required this.backgroundPrimary,
    required this.backgroundSurface,
    required this.backgroundElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textOnAccent,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.borderSubtle,
    required this.borderStrong,
    required this.danger,
    required this.success,
    required this.warning,
  });

  /// Light theme semantic colors.
  static const SemanticColors light = SemanticColors(
    backgroundPrimary: ColorPrimitives.gray50,
    backgroundSurface: ColorPrimitives.neutralWhite,
    backgroundElevated: ColorPrimitives.neutralWhite,
    textPrimary: ColorPrimitives.gray900,
    textSecondary: ColorPrimitives.gray600,
    textOnAccent: ColorPrimitives.neutralWhite,
    accentPrimary: ColorPrimitives.brandBlue500,
    accentSecondary: ColorPrimitives.accentPurple500,
    borderSubtle: ColorPrimitives.gray200,
    borderStrong: ColorPrimitives.gray300,
    danger: ColorPrimitives.accentRed500,
    success: ColorPrimitives.accentGreen500,
    warning: Color(0xFFFFA726),
  );

  /// Dark theme semantic colors.
  static const SemanticColors dark = SemanticColors(
    backgroundPrimary: ColorPrimitives.gray900,
    backgroundSurface: ColorPrimitives.gray800,
    backgroundElevated: Color(0xFF111827),
    textPrimary: ColorPrimitives.neutralWhite,
    textSecondary: ColorPrimitives.gray300,
    textOnAccent: ColorPrimitives.neutralWhite,
    accentPrimary: ColorPrimitives.brandBlue300,
    accentSecondary: ColorPrimitives.accentPurple500,
    borderSubtle: ColorPrimitives.gray600,
    borderStrong: ColorPrimitives.gray300,
    danger: ColorPrimitives.accentRed500,
    success: ColorPrimitives.accentGreen500,
    warning: Color(0xFFFFA726),
  );

  @override
  SemanticColors copyWith({
    Color? backgroundPrimary,
    Color? backgroundSurface,
    Color? backgroundElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? textOnAccent,
    Color? accentPrimary,
    Color? accentSecondary,
    Color? borderSubtle,
    Color? borderStrong,
    Color? danger,
    Color? success,
    Color? warning,
  }) {
    return SemanticColors(
      backgroundPrimary: backgroundPrimary ?? this.backgroundPrimary,
      backgroundSurface: backgroundSurface ?? this.backgroundSurface,
      backgroundElevated: backgroundElevated ?? this.backgroundElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textOnAccent: textOnAccent ?? this.textOnAccent,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentSecondary: accentSecondary ?? this.accentSecondary,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderStrong: borderStrong ?? this.borderStrong,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      warning: warning ?? this.warning,
    );
  }

  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      backgroundPrimary:
          Color.lerp(backgroundPrimary, other.backgroundPrimary, t)!,
      backgroundSurface:
          Color.lerp(backgroundSurface, other.backgroundSurface, t)!,
      backgroundElevated:
          Color.lerp(backgroundElevated, other.backgroundElevated, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textOnAccent: Color.lerp(textOnAccent, other.textOnAccent, t)!,
      accentPrimary: Color.lerp(accentPrimary, other.accentPrimary, t)!,
      accentSecondary:
          Color.lerp(accentSecondary, other.accentSecondary, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension SemanticColorsX on BuildContext {
  SemanticColors get colors =>
      Theme.of(this).extension<SemanticColors>() ?? SemanticColors.light;
}


