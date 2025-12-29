import 'package:flutter/material.dart';

import '../tokens/typography_tokens.dart';
import '../tokens/color_tokens.dart';

class DSText extends StatelessWidget {
  final String data;
  final TypographyRole role;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextStyle? style;
  final TextOverflow? overflow;

  const DSText(
    this.data, {
    super.key,
    required this.role,
    this.color,
    this.textAlign,
    this.maxLines,
    this.style,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = context.textStyle(role);
    final colors = context.colors;

    return Text(
      data,
      style: (style ?? baseStyle).copyWith(
        color: color ?? style?.color ?? baseStyle.color ?? colors.textPrimary,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
    );
  }
}


