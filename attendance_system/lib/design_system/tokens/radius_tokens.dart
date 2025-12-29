import 'package:flutter/widgets.dart';

/// Corner radius tokens for consistent rounding.
class RadiusTokens {
  RadiusTokens._();

  static const double radiusSmall = 4;
  static const double radiusMedium = 8;
  static const double radiusLarge = 16;
  static const double radiusXL = 24;

  static const BorderRadius card =
      BorderRadius.all(Radius.circular(radiusLarge));

  static const BorderRadius button =
      BorderRadius.all(Radius.circular(radiusMedium));

  static const BorderRadius pillSmall =
      BorderRadius.all(Radius.circular(radiusSmall));
}


