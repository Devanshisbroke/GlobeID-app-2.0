import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_provider.dart';
import '_search_screen.dart';

class FoodScreen extends ConsumerWidget {
  const FoodScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(globeIdApiProvider);
    return ServiceListScreen(
      title: 'Food',
      icon: Icons.restaurant_rounded,
      tone: const Color(0xFFE11D48),
      heroLabel: 'Local dining concierge',
      fetcher: () async {
        final data = await api.foodSearch({'city': 'San Francisco'});
        return ((data['items'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
      },
    );
  }
}
