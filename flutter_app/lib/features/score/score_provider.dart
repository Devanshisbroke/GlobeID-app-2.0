import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/api_provider.dart';
import '../../data/models/travel_score.dart';

final scoreProvider = FutureProvider<TravelScore>((ref) async {
  final api = ref.read(globeIdApiProvider);
  return api.scoreSnapshot();
});
