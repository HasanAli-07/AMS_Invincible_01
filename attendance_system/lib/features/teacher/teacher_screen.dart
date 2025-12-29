import 'package:flutter/material.dart';

import '../../design_system/components/ds_scaffold.dart';
import '../../design_system/components/ds_text.dart';
import '../../design_system/components/ds_card.dart';
import '../../design_system/components/ds_button.dart';
import '../../design_system/tokens/typography_tokens.dart';
import '../../design_system/tokens/spacing_tokens.dart';
import '../posts/posts_page.dart';

class TeacherScreen extends StatelessWidget {
  const TeacherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DSScaffold(
      title: 'Teacher Dashboard',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DSCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DSText(
                  'Teacher Dashboard',
                  role: TypographyRole.headline,
                ),
                Insets.spaceVertical8,
                DSText(
                  'You can view and create announcements for your classes.',
                  role: TypographyRole.body,
                ),
                Insets.spaceVertical16,
                DSButton(
                  label: 'Open Posts & Announcements',
                  icon: Icons.article_outlined,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PostsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

