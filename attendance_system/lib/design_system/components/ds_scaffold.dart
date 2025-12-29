import 'package:flutter/material.dart';

import '../tokens/color_tokens.dart';
import '../tokens/spacing_tokens.dart';
import 'ds_text.dart';
import '../tokens/typography_tokens.dart';

class DSScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final Widget? leading;
  final Widget? trailing;
  final Widget? bottomNavigation;

  const DSScaffold({
    super.key,
    this.title,
    required this.body,
    this.leading,
    this.trailing,
    this.bottomNavigation,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: title == null
          ? null
          : AppBar(
              backgroundColor: colors.backgroundSurface,
              elevation: 0,
              centerTitle: true,
              leading: leading,
              title: DSText(
                title!,
                role: TypographyRole.title,
              ),
              actions: trailing == null ? null : [trailing!],
            ),
      body: Padding(
        padding: Insets.screenPadding,
        child: body,
      ),
      bottomNavigationBar: bottomNavigation,
    );
  }
}

