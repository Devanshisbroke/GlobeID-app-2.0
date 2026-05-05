import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_provider.dart';
import '_search_screen.dart';

class RidesScreen extends ConsumerWidget {
  const RidesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.read(globeIdApiProvider);
    return ServiceListScreen(
      title: 'Rides',
      icon: Icons.directions_car_rounded,
      tone: const Color(0xFFEA580C),
      fetcher: () async {
        final data = await api.ridesSearch({'city': 'San Francisco'});
        return ((data['items'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
      },
    );
  }
}
