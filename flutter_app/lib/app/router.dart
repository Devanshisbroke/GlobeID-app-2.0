import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/analytics/analytics_screen.dart';
import '../features/copilot/copilot_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/feed/feed_screen.dart';
import '../features/home/home_screen.dart';
import '../features/identity/identity_screen.dart';
import '../features/intelligence/intelligence_screen.dart';
import '../features/kiosk/kiosk_screen.dart';
import '../features/lock/lock_screen.dart';
import '../features/map/map_screen.dart';
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
import '../features/services/activities_screen.dart';
import '../features/services/food_screen.dart';
import '../features/services/hotels_screen.dart';
import '../features/services/rides_screen.dart';
import '../features/services/services_hub_screen.dart';
import '../features/services/transport_screen.dart';
import '../features/security/session_lock_provider.dart';
import '../features/social/social_screen.dart';
import '../features/timeline/timeline_screen.dart';
import '../features/travel/travel_screen.dart';
import '../features/trip/trip_detail_screen.dart';
import '../features/vault/vault_screen.dart';
import '../features/wallet/pass_detail_screen.dart';
import '../features/wallet/wallet_screen.dart';
import 'app_shell.dart';

/// Premium slide-up + fade transition used for secondary routes.
CustomTransitionPage<void> _slideFade(LocalKey key, Widget child) {
  return CustomTransitionPage<void>(
    key: key,
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (_, anim, __, c) {
      final t = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: t,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(t),
          child: c,
        ),
      );
    },
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
      _route('/scan', (_, __) => const ScannerScreen()),
      _route('/analytics', (_, __) => const AnalyticsScreen()),
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
      _route('/services/food', (_, __) => const FoodScreen()),
      _route('/services/activities', (_, __) => const ActivitiesScreen()),
      _route('/services/transport', (_, __) => const TransportScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text('No route for ${state.uri}')),
    ),
  );
});
