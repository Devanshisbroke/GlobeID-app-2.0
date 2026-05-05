import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_provider.dart';
import '_search_screen.dart';

class TransportScreen extends ConsumerWidget {
  const TransportScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(globeIdApiProvider);
    return ServiceListScreen(
      title: 'Transport',
      icon: Icons.train_rounded,
      tone: const Color(0xFF1D4ED8),
      fetcher: () async {
        final data = await api
            .localServices({'city': 'San Francisco', 'kind': 'transport'});
        return ((data['items'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
      },
    );
  }
}
