import 'package:flutter/widgets.dart';

/// Spacing scale tokens (in logical pixels).
/// Use these instead of raw numbers in paddings/margins.
class SpacingTokens {
  SpacingTokens._();

  static const double space2 = 2;
  static const double space4 = 4;
  static const double space6 = 6;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space48 = 48;
}

/// Convenience helpers to create EdgeInsets from spacing tokens.
class Insets {
  Insets._();

  static const EdgeInsets screenPadding =
      EdgeInsets.all(SpacingTokens.space24);

  static const EdgeInsets cardPadding =
      EdgeInsets.all(SpacingTokens.space16);

  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: SpacingTokens.space16,
    vertical: SpacingTokens.space12,
  );

  static const SizedBox spaceVertical4 =
      SizedBox(height: SpacingTokens.space4);
  static const SizedBox spaceVertical8 =
      SizedBox(height: SpacingTokens.space8);
  static const SizedBox spaceVertical12 =
      SizedBox(height: SpacingTokens.space12);
  static const SizedBox spaceVertical16 =
      SizedBox(height: SpacingTokens.space16);
  static const SizedBox spaceVertical24 =
      SizedBox(height: SpacingTokens.space24);
  static const SizedBox spaceVertical32 =
      SizedBox(height: SpacingTokens.space32);
}


