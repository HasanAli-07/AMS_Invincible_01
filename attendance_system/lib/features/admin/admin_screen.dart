import 'package:flutter/material.dart';

import '../../design_system/components/ds_scaffold.dart';
import '../../design_system/components/ds_text.dart';
import '../../design_system/components/ds_card.dart';
import '../../design_system/tokens/typography_tokens.dart';
import '../../design_system/tokens/spacing_tokens.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DSScaffold(
      title: 'Admin Dashboard',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DSCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(
                  'Admin Dashboard',
                  role: TypographyRole.headline,
                ),
                Insets.spaceVertical8,
                DSText(
                  'This screen is using DSScaffold, DSCard and DSText.',
                  role: TypographyRole.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

