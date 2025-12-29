import 'package:flutter/material.dart';

import '../tokens/color_tokens.dart';
import '../tokens/spacing_tokens.dart';

class DSIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double? size;

  const DSIcon({
    super.key,
    required this.icon,
    this.color,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Icon(
      icon,
      size: size ?? SpacingTokens.space24,
      color: color ?? colors.textSecondary,
    );
  }
}


