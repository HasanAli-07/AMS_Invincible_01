import 'package:flutter/material.dart';

import '../../design_system/components/ds_button.dart';
import '../../design_system/components/ds_card.dart';
import '../../design_system/components/ds_scaffold.dart';
import '../../design_system/components/ds_text.dart';
import '../../design_system/tokens/spacing_tokens.dart';
import '../../design_system/tokens/typography_tokens.dart';

class RoleSelectorScreen extends StatelessWidget {
  const RoleSelectorScreen({super.key});

  void _navigateTo(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return DSScaffold(
      title: 'Select Role',
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DSCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DSText(
                  'Attendance System – Setup Complete',
                  role: TypographyRole.headline,
                  textAlign: TextAlign.center,
                ),
                Insets.spaceVertical24,
                DSText(
                  'Choose a role to navigate to its dashboard. This is using the token-based design system.',
                  role: TypographyRole.body,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Insets.spaceVertical32,
          DSButton(
            label: 'Admin',
            onPressed: () => _navigateTo(context, '/admin'),
          ),
          Insets.spaceVertical12,
          DSButton(
            label: 'Principal',
            onPressed: () => _navigateTo(context, '/principal'),
            variant: DSButtonVariant.secondary,
          ),
          Insets.spaceVertical12,
          DSButton(
            label: 'Teacher',
            onPressed: () => _navigateTo(context, '/teacher'),
          ),
          Insets.spaceVertical12,
          DSButton(
            label: 'Student',
            onPressed: () => _navigateTo(context, '/student'),
          ),
        ],
      ),
    );
  }
}

