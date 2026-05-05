import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';
import '../../widgets/page_scaffold.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const PageScaffold(
      title: 'Social',
      subtitle: 'Follow your traveller circle',
      body: EmptyState(
        title: 'Social feed',
        message:
            'Follow friends, share pinned trips, and react to milestones — coming online soon.',
        icon: Icons.group_rounded,
      ),
    );
  }
}
