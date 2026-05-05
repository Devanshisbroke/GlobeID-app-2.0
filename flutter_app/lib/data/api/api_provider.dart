import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import 'globeid_api.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final globeIdApiProvider = Provider<GlobeIdApi>((ref) {
  return GlobeIdApi(ref.watch(apiClientProvider));
});
