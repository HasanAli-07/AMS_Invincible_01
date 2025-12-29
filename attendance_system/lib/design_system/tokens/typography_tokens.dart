import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'color_tokens.dart';

/// Typography tokens representing Figma-style text styles.
class TypographyTokens {
  TypographyTokens._();

  static TextTheme textTheme(SemanticColors colors) {
    final base = GoogleFonts.poppinsTextTheme();

    return base.copyWith(
      // Display large: big numbers / hero headlines
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.2,
        color: colors.textPrimary,
      ),
      // Headline: section titles
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.3,
        color: colors.textPrimary,
      ),
      // Title: smaller titles / card titles
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.3,
        color: colors.textPrimary,
      ),
      // Body text
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.5,
        color: colors.textSecondary,
      ),
      // Caption
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.4,
        color: colors.textSecondary,
      ),
      // Button text
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.2,
        color: colors.textOnAccent,
      ),
    );
  }
}

/// Semantic accessors for text styles, named like Figma styles.
enum TypographyRole {
  displayLarge,
  headline,
  title,
  body,
  caption,
  button,
}

extension TypographyThemeX on BuildContext {
  TextStyle textStyle(TypographyRole role) {
    final theme = Theme.of(this).textTheme;
    switch (role) {
      case TypographyRole.displayLarge:
        return theme.displayLarge!;
      case TypographyRole.headline:
        return theme.headlineMedium!;
      case TypographyRole.title:
        return theme.titleMedium!;
      case TypographyRole.body:
        return theme.bodyMedium!;
      case TypographyRole.caption:
        return theme.bodySmall!;
      case TypographyRole.button:
        return theme.labelLarge!;
    }
  }
}


