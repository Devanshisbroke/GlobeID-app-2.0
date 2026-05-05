import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_provider.dart';
import '_search_screen.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(globeIdApiProvider);
    return ServiceListScreen(
      title: 'Activities',
      icon: Icons.local_activity_rounded,
      tone: const Color(0xFF059669),
      fetcher: () async {
        final data = await api.localServices({'city': 'San Francisco'});
        return ((data['items'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
      },
    );
  }
}
