import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/analytics/analytics_screen.dart';
import '../features/copilot/copilot_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/feed/feed_screen.dart';
import '../features/home/home_screen.dart';
import '../features/identity/identity_screen.dart';
import '../features/inbox/inbox_screen.dart';
import '../features/intelligence/intelligence_screen.dart';
import '../features/kiosk/kiosk_screen.dart';
import '../features/lock/lock_screen.dart';
import '../features/map/map_screen.dart';
import '../features/multi_currency/multi_currency_pour_screen.dart';
import '../features/multi_currency/multi_currency_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/onboarding_provider.dart';
import '../features/boarding_pass/boarding_pass_live_screen.dart';
import '../features/passport_book/passport_book_screen.dart';
import '../features/passport_book/passport_live_screen.dart';
import '../features/planner/planner_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/receipt/receipt_screen.dart';
import '../features/scanner/scanner_screen.dart';
import '../features/airport/airport_screen.dart';
import '../features/airport/airport_orchestrator.dart';
import '../features/arrival/arrival_welcome_screen.dart';
import '../features/connectivity/esim_screen.dart';
import '../features/country/country_profile_screen.dart';
import '../features/customs/customs_declaration_screen.dart';
import '../features/emergency/emergency_screen.dart';
import '../features/globe/cinematic_globe_screen.dart';
import '../features/itinerary/itinerary_builder_screen.dart';
import '../features/journal/trip_journal_screen.dart';
import '../features/lounge/lounge_screen.dart';
import '../features/packing/packing_checklist_screen.dart';
import '../features/phrasebook/phrasebook_screen.dart';
import '../features/sensors/premium_showcase_screen.dart';
import '../features/sensors/sensors_lab_screen.dart';
import '../features/services/activities_screen.dart';
import '../features/services/flights_screen.dart';
import '../features/services/food_screen.dart';
import '../features/services/hotels_screen.dart';
import '../features/services/ride_live_screen.dart';
import '../features/services/rides_screen.dart';
import '../features/services/services_hub_screen.dart';
import '../features/services/transport_screen.dart';
import '../features/travel_os/travel_os_screen.dart';
import '../features/wallet/wallet_flows_screen.dart';
import '../features/wallet/trip_wallet_screen.dart';
import '../features/discover/discover_screen.dart';
import '../features/security/audit_log_screen.dart';
import '../features/security/session_lock_provider.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/settings_subscreens.dart';
import '../features/social/social_screen.dart';
import '../features/timeline/timeline_screen.dart';
import '../features/travel/travel_screen.dart';
import '../features/trip/trip_detail_screen.dart';
import '../features/vault/vault_screen.dart';
import '../features/wallet/pass_detail_screen.dart';
import '../features/wallet/wallet_screen.dart';
import '../motion/motion.dart';
import 'app_shell.dart';

/// Premium slide-up + scale + blur transition used for secondary
/// routes. See `motion/motion.dart` for the easing + blur curve.
CustomTransitionPage<void> _slideFade(LocalKey key, Widget child) {
  return CustomTransitionPage<void>(
    key: key,
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: premiumSlideTransition,
    child: child,
  );
}

GoRoute _route(
    String path, Widget Function(BuildContext, GoRouterState) build) {
  return GoRoute(
    path: path,
    pageBuilder: (ctx, state) => _slideFade(state.pageKey, build(ctx, state)),
  );
}

/// All 25 routes from `src/App.tsx`, mapped into a [GoRouter] with a
/// [ShellRoute] for the five core tabs that share the bottom nav.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final path = state.uri.path;
      final onboarding = ref.read(onboardingProvider);
      final sessionLock = ref.read(sessionLockProvider);

      if (!onboarding.completed && path != '/onboarding') {
        return '/onboarding';
      }

      if (onboarding.completed &&
          sessionLock.locked &&
          path != '/lock' &&
          path != '/onboarding') {
        return '/lock';
      }

      if (onboarding.completed && path == '/onboarding') {
        return '/';
      }

      if (!sessionLock.locked && path == '/lock') {
        return '/';
      }

      return null;
    },
    routes: [
      // Gate routes (full-screen, no shell)
      _route('/lock', (_, __) => const LockScreen()),
      _route('/onboarding', (_, __) => const OnboardingScreen()),

      // Shell routes — share bottom nav
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
          GoRoute(
              path: '/identity', builder: (_, __) => const IdentityScreen()),
          GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen()),
          GoRoute(path: '/travel', builder: (_, __) => const TravelScreen()),
          GoRoute(
              path: '/services', builder: (_, __) => const ServicesHubScreen()),
          GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
        ],
      ),

      // Secondary routes (full-screen, no shell) — premium slide+fade.
      _route('/profile', (_, __) => const ProfileScreen()),
      _route('/kiosk-sim', (_, __) => const KioskScreen()),
      _route('/receipt', (_, __) => const ReceiptScreen()),
      _route('/timeline', (_, __) => const TimelineScreen()),
      _route('/planner', (_, __) => const PlannerScreen()),
      _route('/copilot', (_, __) => const CopilotScreen()),
      _route('/social', (_, __) => const SocialScreen()),
      _route('/explore', (_, __) => const ExploreScreen()),
      _route('/passport-book', (_, __) => const PassportBookScreen()),
      _route('/passport-live', (_, __) => const PassportLiveScreen()),
      _route(
        '/boarding/:tripId/:legId',
        (_, state) => BoardingPassLiveScreen(
          tripId: state.pathParameters['tripId']!,
          legId: state.pathParameters['legId']!,
        ),
      ),
      _route('/intelligence', (_, __) => const IntelligenceScreen()),
      _route('/explorer', (_, __) => const ExploreScreen()),
      _route('/vault', (_, __) => const VaultScreen()),
      _route('/feed', (_, __) => const FeedScreen()),
      _route('/multi-currency', (_, __) => const MultiCurrencyScreen()),
      _route('/multi-currency-pour',
          (_, __) => const MultiCurrencyPourScreen()),
      _route('/scan', (_, __) => const ScannerScreen()),
      _route('/analytics', (_, __) => const AnalyticsScreen()),
      _route('/audit-log', (_, __) => const AuditLogScreen()),
      _route('/inbox', (_, __) => const InboxScreen()),
      _route('/discover', (_, __) => const DiscoverScreen()),
      _route('/settings', (_, __) => const SettingsScreen()),
      _route(
          '/settings/appearance', (_, __) => const AppearanceSettingsScreen()),
      _route('/settings/notifications',
          (_, __) => const NotificationsSettingsScreen()),
      _route('/settings/security', (_, __) => const SecuritySettingsScreen()),
      _route('/settings/privacy', (_, __) => const PrivacySettingsScreen()),
      _route('/settings/travel', (_, __) => const TravelPrefsScreen()),
      _route('/settings/accessibility',
          (_, __) => const AccessibilitySettingsScreen()),
      _route('/settings/lab', (_, __) => const LabSettingsScreen()),
      _route('/settings/about', (_, __) => const AboutSettingsScreen()),
      _route(
        '/trip/:tripId',
        (_, state) => TripDetailScreen(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        path: '/pass/:passId',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          opaque: false,
          barrierColor: Colors.transparent,
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 320),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: child,
          ),
          child: PassDetailScreen(passId: state.pathParameters['passId']!),
        ),
      ),
      // Services sub-routes
      _route('/services/hotels', (_, __) => const HotelsScreen()),
      _route('/services/rides', (_, __) => const RidesScreen()),
      _route('/services/rides/live', (_, __) => const RideLiveScreen()),
      _route('/services/food', (_, __) => const FoodScreen()),
      _route('/services/flights', (_, __) => const FlightsScreen()),
      _route('/services/activities', (_, __) => const ActivitiesScreen()),
      _route('/services/transport', (_, __) => const TransportScreen()),
      _route('/airport', (_, __) => const AirportScreen()),
      _route('/airport-mode', (_, __) => const AirportOrchestratorScreen()),
      _route('/trip-wallet', (_, __) => const TripWalletScreen()),
      _route('/travel-os', (_, __) => const TravelOSScreen()),
      _route('/arrival', (_, __) => const ArrivalWelcomeScreen()),
      _route('/sensors-lab', (_, __) => const SensorsLabScreen()),
      _route('/premium-showcase', (_, __) => const PremiumShowcaseScreen()),
      _route('/globe-cinematic', (_, __) => const CinematicGlobeScreen()),
      _route('/lounge', (_, __) => const LoungeScreen()),
      _route('/esim', (_, __) => const EsimScreen()),
      _route('/phrasebook', (_, __) => const PhrasebookScreen()),
      _route('/emergency', (_, __) => const EmergencySosScreen()),
      _route('/itinerary', (_, __) => const ItineraryBuilderScreen()),
      _route('/country', (_, __) => const CountryProfileScreen()),
      _route('/packing', (_, __) => const PackingChecklistScreen()),
      _route('/customs', (_, __) => const CustomsDeclarationScreen()),
      _route('/journal', (_, __) => const TripJournalScreen()),
      _route(
        '/wallet/send',
        (_, __) => const WalletFlowScreen(flow: WalletFlow.send),
      ),
      _route(
        '/wallet/receive',
        (_, __) => const WalletFlowScreen(flow: WalletFlow.receive),
      ),
      _route(
        '/wallet/scan',
        (_, __) => const WalletFlowScreen(flow: WalletFlow.scanPay),
      ),
      _route(
        '/wallet/exchange',
        (_, __) => const WalletFlowScreen(flow: WalletFlow.exchange),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text('No route for ${state.uri}')),
    ),
  );
});
