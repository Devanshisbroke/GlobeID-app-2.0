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
import '../features/passport_book/passport_book_screen.dart';
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
import '../features/social/social_screen.dart';
import '../features/timeline/timeline_screen.dart';
import '../features/travel/travel_screen.dart';
import '../features/trip/trip_detail_screen.dart';
import '../features/vault/vault_screen.dart';
import '../features/wallet/pass_detail_screen.dart';
import '../features/wallet/wallet_screen.dart';
import 'app_shell.dart';

/// All 25 routes from `src/App.tsx`, mapped into a [GoRouter] with a
/// [ShellRoute] for the five core tabs that share the bottom nav.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      // Gate routes (full-screen, no shell)
      GoRoute(path: '/lock', builder: (_, __) => const LockScreen()),
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreen()),

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

      // Secondary routes (full-screen, no shell)
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/kiosk-sim', builder: (_, __) => const KioskScreen()),
      GoRoute(path: '/receipt', builder: (_, __) => const ReceiptScreen()),
      GoRoute(path: '/timeline', builder: (_, __) => const TimelineScreen()),
      GoRoute(path: '/planner', builder: (_, __) => const PlannerScreen()),
      GoRoute(path: '/copilot', builder: (_, __) => const CopilotScreen()),
      GoRoute(path: '/social', builder: (_, __) => const SocialScreen()),
      GoRoute(path: '/explore', builder: (_, __) => const ExploreScreen()),
      GoRoute(
          path: '/passport-book',
          builder: (_, __) => const PassportBookScreen()),
      GoRoute(
          path: '/intelligence',
          builder: (_, __) => const IntelligenceScreen()),
      GoRoute(path: '/explorer', builder: (_, __) => const ExploreScreen()),
      GoRoute(path: '/vault', builder: (_, __) => const VaultScreen()),
      GoRoute(path: '/feed', builder: (_, __) => const FeedScreen()),
      GoRoute(
          path: '/multi-currency',
          builder: (_, __) => const MultiCurrencyScreen()),
      GoRoute(path: '/scan', builder: (_, __) => const ScannerScreen()),
      GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
      GoRoute(
        path: '/trip/:tripId',
        builder: (_, state) =>
            TripDetailScreen(tripId: state.pathParameters['tripId']!),
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
      GoRoute(
          path: '/services/hotels', builder: (_, __) => const HotelsScreen()),
      GoRoute(path: '/services/rides', builder: (_, __) => const RidesScreen()),
      GoRoute(path: '/services/food', builder: (_, __) => const FoodScreen()),
      GoRoute(
          path: '/services/activities',
          builder: (_, __) => const ActivitiesScreen()),
      GoRoute(
          path: '/services/transport',
          builder: (_, __) => const TransportScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text('No route for ${state.uri}')),
    ),
  );
});
