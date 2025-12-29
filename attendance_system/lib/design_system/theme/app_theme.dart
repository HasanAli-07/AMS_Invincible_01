import 'package:flutter/material.dart';

import 'light_theme.dart';
import 'dark_theme.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() => buildLightTheme();

  static ThemeData dark() => buildDarkTheme();
}


