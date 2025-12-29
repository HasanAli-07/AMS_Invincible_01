import 'package:flutter/material.dart';

import '../tokens/color_tokens.dart';
import '../tokens/typography_tokens.dart';

ThemeData buildDarkTheme() {
  const colors = SemanticColors.dark;

  final textTheme = TypographyTokens.textTheme(colors);

  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.accentPrimary,
      brightness: Brightness.dark,
      primary: colors.accentPrimary,
      secondary: colors.accentSecondary,
      background: colors.backgroundPrimary,
      surface: colors.backgroundSurface,
      error: colors.danger,
      onPrimary: colors.textOnAccent,
      onSecondary: colors.textOnAccent,
      onBackground: colors.textPrimary,
      onSurface: colors.textPrimary,
      onError: colors.textOnAccent,
    ),
    scaffoldBackgroundColor: colors.backgroundPrimary,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: colors.backgroundSurface,
      elevation: 0,
      foregroundColor: colors.textPrimary,
      centerTitle: true,
      titleTextStyle: textTheme.titleMedium,
    ),
    useMaterial3: true,
    extensions: const <ThemeExtension<dynamic>>[
      colors,
    ],
  );
}


