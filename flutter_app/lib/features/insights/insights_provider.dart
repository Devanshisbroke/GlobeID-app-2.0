import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_provider.dart';

final travelInsightsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(globeIdApiProvider).insightsTravel();
});

final walletInsightsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(globeIdApiProvider).insightsWallet();
});

final activityInsightsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(globeIdApiProvider).insightsActivity();
});

final recommendationsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(globeIdApiProvider).recommendations();
});

final alertsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(globeIdApiProvider).alerts();
});

final budgetProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(globeIdApiProvider).budgetSnapshot();
});

final loyaltyProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(globeIdApiProvider).loyaltySnapshot();
});

final fraudProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(globeIdApiProvider).fraudFindings();
});

final contextProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(globeIdApiProvider).contextCurrent();
});
