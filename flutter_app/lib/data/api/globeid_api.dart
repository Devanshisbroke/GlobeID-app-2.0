import '../../core/network/api_client.dart';
import '../models/lifecycle.dart';
import '../models/travel_document.dart';
import '../models/travel_record.dart';
import '../models/travel_score.dart';
import '../models/user_profile.dart';
import '../models/wallet_models.dart';

/// Dart port of the typed `api` object in `src/lib/apiClient.ts`. Exposes
/// every Hono endpoint listed in `server/src/routes/`.
class GlobeIdApi {
  GlobeIdApi(this._client);

  final ApiClient _client;

  // ── User ────────────────────────────────────────────────────────────
  Future<UserProfile> me() async {
    final j = await _client.get<Map<String, dynamic>>('/user');
    return UserProfile.fromJson(j);
  }

  Future<UserProfile> patchMe(Map<String, dynamic> patch) async {
    final j = await _client.patch<Map<String, dynamic>>('/user', body: patch);
    return UserProfile.fromJson(j);
  }

  // ── Trips (legacy travel-record list) ───────────────────────────────
  Future<List<TravelRecord>> tripsList() async {
    final j = await _client.get<List<dynamic>>('/trips');
    return j
        .map((e) => TravelRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> tripsCreate(List<TravelRecord> records) =>
      _client.post<Map<String, dynamic>>('/trips',
          body: {'records': records.map((r) => r.toJson()).toList()});

  Future<Map<String, dynamic>> tripsRemove(String id) =>
      _client.delete<Map<String, dynamic>>('/trips/$id');

  Future<List<TravelDocument>> documents() async {
    final j = await _client.get<List<dynamic>>('/user/documents');
    return j
        .map((e) => TravelDocument.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Insights ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> insightsTravel() =>
      _client.get<Map<String, dynamic>>('/insights/travel');
  Future<Map<String, dynamic>> insightsWallet() =>
      _client.get<Map<String, dynamic>>('/insights/wallet');
  Future<Map<String, dynamic>> insightsActivity() =>
      _client.get<Map<String, dynamic>>('/insights/activity');

  // ── Recommendations ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> recommendations() =>
      _client.get<Map<String, dynamic>>('/recommendations');

  // ── Alerts ──────────────────────────────────────────────────────────
  Future<List<dynamic>> alerts() => _client.get<List<dynamic>>('/alerts');
  Future<Map<String, dynamic>> patchAlert(
          String id, Map<String, dynamic> patch) =>
      _client.patch<Map<String, dynamic>>('/alerts/$id', body: patch);

  // ── Copilot ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> copilotRespond(String prompt) => _client
      .post<Map<String, dynamic>>('/copilot/respond', body: {'prompt': prompt});
  Future<List<dynamic>> copilotHistory() =>
      _client.get<List<dynamic>>('/copilot/history');
  Future<Map<String, dynamic>> copilotClear() =>
      _client.delete<Map<String, dynamic>>('/copilot/history');

  // ── Planner ─────────────────────────────────────────────────────────
  Future<List<dynamic>> plannerList() =>
      _client.get<List<dynamic>>('/planner/trips');
  Future<Map<String, dynamic>> plannerUpsert(Map<String, dynamic> trip) =>
      _client.post<Map<String, dynamic>>('/planner/trips', body: trip);
  Future<Map<String, dynamic>> plannerRemove(String id) =>
      _client.delete<Map<String, dynamic>>('/planner/trips/$id');

  // ── Context ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> contextCurrent() =>
      _client.get<Map<String, dynamic>>('/context/current');

  // ── Lifecycle ───────────────────────────────────────────────────────
  Future<List<TripLifecycle>> lifecycleTrips() async {
    final j = await _client.get<List<dynamic>>('/lifecycle/trips');
    return j
        .map((e) => TripLifecycle.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> flightStatus(String legId) =>
      _client.get<Map<String, dynamic>>('/lifecycle/flights/$legId');

  // ── Wallet ──────────────────────────────────────────────────────────
  Future<WalletSnapshot> walletSnapshot() async {
    final j = await _client.get<Map<String, dynamic>>('/wallet');
    return WalletSnapshot.fromJson(j);
  }

  Future<Map<String, dynamic>> walletRecord(Map<String, dynamic> req) =>
      _client.post<Map<String, dynamic>>('/wallet/transactions', body: req);

  Future<Map<String, dynamic>> walletConvert(Map<String, dynamic> req) =>
      _client.post<Map<String, dynamic>>('/wallet/convert', body: req);

  Future<Map<String, dynamic>> walletUpdateState(Map<String, dynamic> req) =>
      _client.patch<Map<String, dynamic>>('/wallet/state', body: req);

  // ── Loyalty ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> loyaltySnapshot() =>
      _client.get<Map<String, dynamic>>('/loyalty');
  Future<Map<String, dynamic>> loyaltyEarn(Map<String, dynamic> req) =>
      _client.post<Map<String, dynamic>>('/loyalty/earn', body: req);
  Future<Map<String, dynamic>> loyaltyRedeem(Map<String, dynamic> req) =>
      _client.post<Map<String, dynamic>>('/loyalty/redeem', body: req);

  // ── Safety ──────────────────────────────────────────────────────────
  Future<List<dynamic>> safetyContacts() =>
      _client.get<List<dynamic>>('/safety/contacts');
  Future<Map<String, dynamic>> safetyAddContact(Map<String, dynamic> req) =>
      _client.post<Map<String, dynamic>>('/safety/contacts', body: req);
  Future<Map<String, dynamic>> safetyPatchContact(
          String id, Map<String, dynamic> patch) =>
      _client.patch<Map<String, dynamic>>('/safety/contacts/$id', body: patch);
  Future<Map<String, dynamic>> safetyDeleteContact(String id) =>
      _client.delete<Map<String, dynamic>>('/safety/contacts/$id');

  // ── Score ───────────────────────────────────────────────────────────
  Future<TravelScore> scoreSnapshot() async {
    final j = await _client.get<Map<String, dynamic>>('/score');
    return TravelScore.fromJson(j);
  }

  // ── Weather ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> weatherForecast(String iata, {int days = 7}) =>
      _client
          .get<Map<String, dynamic>>('/weather/forecast?iata=$iata&days=$days');

  // ── Budget ──────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> budgetSnapshot() =>
      _client.get<Map<String, dynamic>>('/budget');
  Future<Map<String, dynamic>> upsertCap(Map<String, dynamic> req) =>
      _client.put<Map<String, dynamic>>('/budget/caps', body: req);
  Future<Map<String, dynamic>> deleteCap(String scope) =>
      _client.delete<Map<String, dynamic>>('/budget/caps/$scope');

  // ── Fraud ───────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> fraudFindings() =>
      _client.get<Map<String, dynamic>>('/fraud/findings');
  Future<Map<String, dynamic>> fraudScan() =>
      _client.post<Map<String, dynamic>>('/fraud/scan');

  // ── Exchange ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> exchangeRates({String base = 'USD'}) =>
      _client.get<Map<String, dynamic>>('/exchange/rates?base=$base');
  Future<Map<String, dynamic>> exchangeQuote(
          String from, String to, double amount) =>
      _client.get<Map<String, dynamic>>(
          '/exchange/quote?from=$from&to=$to&amount=$amount');

  // ── Visa ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> visaPolicies({String? citizenship}) {
    final q = citizenship != null ? '?citizenship=$citizenship' : '';
    return _client.get<Map<String, dynamic>>('/visa/policies$q');
  }

  Future<Map<String, dynamic>> visaPolicy(
          String citizenship, String destination) =>
      _client.get<Map<String, dynamic>>(
          '/visa/policy?citizenship=$citizenship&destination=$destination');

  // ── Insurance ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> insurancePlans() =>
      _client.get<Map<String, dynamic>>('/insurance/plans');
  Future<Map<String, dynamic>> insuranceQuote(
          int days, int age, String destination) =>
      _client.get<Map<String, dynamic>>(
          '/insurance/quote?days=$days&age=$age&destination=$destination');

  // ── eSIM ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> esimPlans({String? country}) {
    final q = country != null ? '?country=$country' : '';
    return _client.get<Map<String, dynamic>>('/esim/plans$q');
  }

  // ── Hotels / Food / Rides / Local ──────────────────────────────────
  Future<Map<String, dynamic>> hotelsSearch(Map<String, String> params) {
    final q = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return _client.get<Map<String, dynamic>>('/hotels/search?$q');
  }

  Future<Map<String, dynamic>> hotel(String id) =>
      _client.get<Map<String, dynamic>>('/hotels/$id');

  Future<Map<String, dynamic>> foodSearch(Map<String, String> params) {
    final q = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return _client.get<Map<String, dynamic>>('/food/restaurants?$q');
  }

  Future<Map<String, dynamic>> ridesSearch(Map<String, String> params) {
    final q = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return _client.get<Map<String, dynamic>>('/rides/search?$q');
  }

  Future<Map<String, dynamic>> localServices(Map<String, String> params) {
    final q = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return _client.get<Map<String, dynamic>>('/local/services?$q');
  }
}
