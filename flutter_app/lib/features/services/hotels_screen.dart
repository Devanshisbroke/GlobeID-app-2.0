import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_provider.dart';
import '_search_screen.dart';

class HotelsScreen extends ConsumerWidget {
  const HotelsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(globeIdApiProvider);
    return ServiceListScreen(
      title: 'Hotels',
      icon: Icons.hotel_rounded,
      tone: const Color(0xFF7E22CE),
      heroLabel: 'Tokyo stay intelligence',
      fetcher: () async {
        final data = await api.hotelsSearch({'city': 'San Francisco'});
        return ((data['items'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
      },
    );
  }
}
