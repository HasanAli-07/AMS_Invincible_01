import 'package:flutter/material.dart';

/// Animation duration tokens for consistent timing.
class AnimationTokens {
  AnimationTokens._();

  /// Quick interactions (button taps, toggles)
  static const Duration durationFast = Duration(milliseconds: 200);

  /// Standard transitions (screen transitions, card animations)
  static const Duration durationMedium = Duration(milliseconds: 300);

  /// Slow, deliberate animations (page transitions, complex sequences)
  static const Duration durationSlow = Duration(milliseconds: 500);

  /// Screen entry animation duration
  static const Duration durationScreenEntry = durationMedium;

  /// Button interaction animation duration
  static const Duration durationButtonInteraction = durationFast;
}

/// Animation curve tokens for consistent motion feel.
class AnimationCurves {
  AnimationCurves._();

  /// Standard easing for most animations
  static const Curve standard = Curves.easeInOut;

  /// Smooth, natural motion
  static const Curve smooth = Curves.easeOutCubic;

  /// Quick, snappy interactions
  static const Curve quick = Curves.easeOut;

  /// Screen entry curve
  static const Curve screenEntry = smooth;

  /// Button interaction curve
  static const Curve buttonInteraction = quick;
}

