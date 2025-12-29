import 'package:flutter/material.dart';

import '../tokens/color_tokens.dart';
import '../tokens/spacing_tokens.dart';
import '../tokens/typography_tokens.dart';

class DSProfileChip extends StatelessWidget {
  final String name;
  final String role;
  final VoidCallback? onTap;

  const DSProfileChip({
    super.key,
    required this.name,
    required this.role,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final nameStyle = context.textStyle(TypographyRole.caption).copyWith(
      color: colors.textPrimary,
    );
    final roleStyle = context.textStyle(TypographyRole.caption);

    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';

    final chip = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundColor: colors.accentPrimary,
          radius: SpacingTokens.space16,
          child: Text(
            initials,
            style: context.textStyle(TypographyRole.caption).copyWith(
                  color: colors.textOnAccent,
                ),
          ),
        ),
        const SizedBox(width: SpacingTokens.space8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: nameStyle,
            ),
            Text(
              role,
              style: roleStyle,
            ),
          ],
        ),
      ],
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.space8,
        ),
        child: chip,
      ),
    );
  }
}


