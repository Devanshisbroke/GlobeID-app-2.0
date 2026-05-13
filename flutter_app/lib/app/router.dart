import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../nexus/screens/nexus_passport_screen.dart';
import '../nexus/screens/nexus_travel_os_screen.dart';
import '../nexus/screens/nexus_wallet_screen.dart';
import '../bible/screens/bible_arrival_screen.dart';
import '../bible/screens/bible_boarding_screen.dart';
import '../bible/screens/bible_home_screen.dart';
import '../bible/screens/bible_lock_screen.dart';
import '../bible/screens/bible_lounge_screen.dart';
import '../bible/screens/bible_passport_screen.dart';
import '../bible/screens/bible_trip_screen.dart';
import '../bible/screens/bible_wallet_screen.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/copilot/copilot_hub_screen.dart';
import '../features/copilot/copilot_screen.dart';
import '../features/explore/explore_screen.dart';
import '../features/feed/feed_screen.dart';
import '../features/inbox/inbox_screen.dart';
import '../features/intelligence/intelligence_screen.dart';
import '../features/kiosk/kiosk_screen.dart';
import '../features/lock/lock_screen.dart';
import '../features/multi_currency/multi_currency_pour_screen.dart';
import '../features/multi_currency/multi_currency_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/onboarding_provider.dart';
import '../features/airport_companion/airport_companion_live_screen.dart';
import '../features/arrival_live/arrival_live_screen.dart';
import '../features/boarding_pass/boarding_pass_live_screen.dart';
import '../features/country_intelligence/country_intelligence_live_screen.dart';
import '../features/forex/forex_live_screen.dart';
import '../features/immigration/immigration_live_screen.dart';
import '../features/live_systems/live_systems_hub_screen.dart';
import '../features/lounge_live/lounge_live_screen.dart';
import '../features/navigation_live/navigation_live_screen.dart';
import '../features/passport_book/passport_book_screen.dart';
import '../features/passport_book/passport_live_screen.dart';
import '../features/transit_passes/transit_passes_live_screen.dart';
import '../features/trip_timeline/trip_timeline_live_screen.dart';
import '../features/visa/visa_live_screen.dart';
import '../features/visa/visa_renewal_ceremony.dart';
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
import '../features/debug/error_log_screen.dart';
import '../features/emergency/emergency_screen.dart';
import '../features/itinerary/itinerary_builder_screen.dart';
import '../features/journal/trip_journal_screen.dart';
import '../features/lounge/lounge_screen.dart';
import '../features/packing/packing_checklist_screen.dart';
import '../features/phrasebook/phrasebook_screen.dart';
import '../features/identity/visa_detail_screen.dart';
import '../features/sensors/premium_showcase_screen.dart';
import '../features/sensors/sensors_lab_screen.dart';
import '../features/services/activities_screen.dart';
import '../features/services/flights_screen.dart';
import '../features/services/food_screen.dart';
import '../features/services/hotel_detail_screen.dart';
import '../features/services/hotels_screen.dart';
import '../features/services/restaurant_detail_screen.dart';
import '../features/services/ride_live_screen.dart';
import '../features/services/rides_screen.dart';
import '../features/services/super_services_screen.dart';
import '../features/services/transport_screen.dart';
import '../features/travel_os/travel_os_screen.dart';
import '../features/wallet/wallet_flows_screen.dart';
import '../features/wallet/wallet_scheduled_screen.dart';
import '../features/wallet/wallet_statements_screen.dart';
import '../features/wallet/trip_wallet_screen.dart';
import '../features/security/audit_log_screen.dart';
import '../features/security/session_lock_provider.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/settings_subscreens.dart';
import '../features/social/social_screen.dart';
import '../features/timeline/timeline_screen.dart';
import '../features/trip/trip_detail_screen.dart';
import '../features/vault/credential_detail_screen.dart';
import '../features/vault/issuance_screen.dart';
import '../features/vault/vault_screen.dart';
import '../features/wallet/pass_detail_screen.dart';
import '../motion/motion.dart';
import '../motion/motion_tokens.dart';
import '../os2/screens/os2_airport_orchestrator.dart';
import '../os2/screens/os2_boarding_pass.dart';
import '../os2/screens/os2_concierge_hub.dart';
import '../os2/screens/os2_copilot_screen.dart';
import '../os2/screens/os2_lock_screen.dart';
import '../os2/screens/os2_onboarding_screen.dart';
import '../os2/screens/os2_passport_book_screen.dart';
import '../os2/screens/os2_settings_screen.dart';
import '../os2/screens/os2_treasury_hub.dart';
import '../os2/screens/os2_trust_hub.dart';
import '../os2/shell/os2_shell.dart';
import '../os2/worlds/discover_world.dart';
import '../os2/worlds/identity_world.dart';
import '../os2/worlds/pulse_world.dart';
import '../os2/worlds/services_world.dart';
import '../os2/worlds/travel_world.dart';
import '../os2/worlds/wallet_world.dart';
import 'theme/ux_bible.dart';

/// Premium slide-up + scale + blur transition used for secondary
/// routes. See `motion/motion.dart` for the easing + blur curve.
CustomTransitionPage<void> _slideFade(LocalKey key, Widget child) {
  return CustomTransitionPage<void>(
    key: key,
    transitionDuration: Motion.dPage,
    reverseTransitionDuration: Motion.dQuickReverse,
    opaque: true,
    barrierColor: const Color(0xFF000000),
    transitionsBuilder: premiumSlideTransition,
    child: RepaintBoundary(child: child),
  );
}

GoRoute _route(
    String path, Widget Function(BuildContext, GoRouterState) build) {
  return GoRoute(
    path: path,
    pageBuilder: (ctx, state) => _slideFade(state.pageKey, build(ctx, state)),
  );
}

// ─── Bible §5.3 — eight named transitions wired to go_router ─────────

/// `atmosphericDescent` — used for descending the altitude stack
/// (Globe → Travel → Trip → Boarding). Vertical slide + scale +
/// blur lens that resolves on land.
CustomTransitionPage<void> _atmosphericDescent(LocalKey key, Widget child) {
  return CustomTransitionPage<void>(
    key: key,
    transitionDuration: Motion.dPage,
    reverseTransitionDuration: Motion.dQuickReverse,
    opaque: true,
    barrierColor: const Color(0xFF000000),
    transitionsBuilder: (_, animation, secondary, c) =>
        BibleTransitions.atmosphericDescent(animation, secondary, c),
    child: RepaintBoundary(child: child),
  );
}

GoRoute _descentRoute(
    String path, Widget Function(BuildContext, GoRouterState) build) {
  return GoRoute(
    path: path,
    pageBuilder: (ctx, state) =>
        _atmosphericDescent(state.pageKey, build(ctx, state)),
  );
}

/// `blurFadeTransition` — incoming fades in while background blurs
/// from σ=8→0. Used for modal-grade presentations (intelligence,
/// vault, audit log).
CustomTransitionPage<void> _blurFade(LocalKey key, Widget child) {
  return CustomTransitionPage<void>(
    key: key,
    transitionDuration: Motion.dModal,
    reverseTransitionDuration: Motion.dQuickReverse,
    opaque: true,
    barrierColor: const Color(0xFF000000),
    transitionsBuilder: (_, animation, secondary, c) =>
        BibleTransitions.blurFade(animation, secondary, c),
    child: RepaintBoundary(child: child),
  );
}

GoRoute _blurFadeRoute(
    String path, Widget Function(BuildContext, GoRouterState) build) {
  return GoRoute(
    path: path,
    pageBuilder: (ctx, state) => _blurFade(state.pageKey, build(ctx, state)),
  );
}

/// `dropTransition` — slide down with bounce. Used for
/// notifications, alerts, kiosk overlays.
CustomTransitionPage<void> _drop(LocalKey key, Widget child) {
  return CustomTransitionPage<void>(
    key: key,
    transitionDuration: Motion.dModal,
    reverseTransitionDuration: Motion.dQuickReverse,
    opaque: true,
    barrierColor: const Color(0xFF000000),
    transitionsBuilder: (_, animation, secondary, c) =>
        BibleTransitions.drop(animation, secondary, c),
    child: RepaintBoundary(child: child),
  );
}

GoRoute _dropRoute(
    String path, Widget Function(BuildContext, GoRouterState) build) {
  return GoRoute(
    path: path,
    pageBuilder: (ctx, state) => _drop(state.pageKey, build(ctx, state)),
  );
}

/// `sheetTransition` — Apple-grade sheet presentation.
///
/// Slides up from the bottom with a soft spring and scales the
/// previous content very slightly. Used for surfaces the user
/// expects to swipe down on (statements, scheduled, flows).
/// Pairs with [Motion.dSheet] (320 ms in, 220 ms out).
CustomTransitionPage<void> _sheet(LocalKey key, Widget child) {
  return CustomTransitionPage<void>(
    key: key,
    transitionDuration: Motion.dSheet,
    reverseTransitionDuration: Motion.dQuickReverse,
    opaque: true,
    barrierColor: const Color(0xFF000000),
    transitionsBuilder: premiumSheetTransition,
    child: RepaintBoundary(child: child),
  );
}

GoRoute _sheetRoute(
    String path, Widget Function(BuildContext, GoRouterState) build) {
  return GoRoute(
    path: path,
    pageBuilder: (ctx, state) => _sheet(state.pageKey, build(ctx, state)),
  );
}

/// `slideLateralTransition` — iOS push from right with parallax
/// depth on exit. Used for back-navigable detail flows (settings).
CustomTransitionPage<void> _slideLateral(LocalKey key, Widget child) {
  return CustomTransitionPage<void>(
    key: key,
    transitionDuration: Motion.dSheet,
    reverseTransitionDuration: Motion.dQuickReverse,
    opaque: true,
    barrierColor: const Color(0xFF000000),
    transitionsBuilder: (_, animation, secondary, c) =>
        BibleTransitions.slideLateral(animation, secondary, c),
    child: RepaintBoundary(child: child),
  );
}

GoRoute _slideLateralRoute(
    String path, Widget Function(BuildContext, GoRouterState) build) {
  return GoRoute(
    path: path,
    pageBuilder: (ctx, state) =>
        _slideLateral(state.pageKey, build(ctx, state)),
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
      // Debug — error log viewer. Surfaces the in-memory
      // `ErrorTelemetry` buffer for triage. Safe to keep on all
      // builds; capture is no-op in release.
      _route('/debug/errors', (_, __) => const ErrorLogScreen()),

      // OS 2.0 — the six worlds share `Os2Shell`. Every screen here
      // is a rebuilt-from-scratch surface in `lib/os2/worlds/`.
      // The legacy `AppShell` and the old HomeScreen / IdentityScreen
      // / WalletScreen / TravelScreen / DiscoverScreen /
      // ServicesHubScreen files are no longer reachable from primary
      // navigation. They remain in the tree only because secondary
      // routes (the old detail surfaces) still depend on the legacy
      // theme + chrome.
      ShellRoute(
        builder: (context, state, child) => Os2Shell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const PulseWorld()),
          GoRoute(
              path: '/identity', builder: (_, __) => const IdentityWorld()),
          GoRoute(path: '/wallet', builder: (_, __) => const WalletWorld()),
          GoRoute(path: '/travel', builder: (_, __) => const TravelWorld()),
          GoRoute(
              path: '/discover', builder: (_, __) => const DiscoverWorld()),
          GoRoute(
              path: '/services', builder: (_, __) => const ServicesWorld()),
          // `/map` was the heavy 3D-globe / 2D-OSM screen. It has
          // been removed; the route redirects into the cinematic
          // Discover atlas (typographic destination intelligence,
          // no geography).
          GoRoute(
            path: '/map',
            redirect: (_, __) => '/discover',
          ),
          // `/services-legacy` exists only so the orphan
          // ServicesHubScreen file does not get pruned by the
          // dead-code shaker while secondary service routes still
          // import bits of it.
        ],
      ),

      // Secondary routes — bible §5.3 named transitions.
      // Settings flows: slideLateral (back-navigable detail).
      _slideLateralRoute('/profile', (_, __) => const ProfileScreen()),
      _slideLateralRoute('/settings', (_, __) => const SettingsScreen()),
      _slideLateralRoute('/settings/appearance',
          (_, __) => const AppearanceSettingsScreen()),
      _slideLateralRoute('/settings/notifications',
          (_, __) => const NotificationsSettingsScreen()),
      _slideLateralRoute(
          '/settings/security', (_, __) => const SecuritySettingsScreen()),
      _slideLateralRoute(
          '/settings/privacy', (_, __) => const PrivacySettingsScreen()),
      _slideLateralRoute(
          '/settings/travel', (_, __) => const TravelPrefsScreen()),
      _slideLateralRoute('/settings/accessibility',
          (_, __) => const AccessibilitySettingsScreen()),
      _slideLateralRoute(
          '/settings/lab', (_, __) => const LabSettingsScreen()),
      _slideLateralRoute(
          '/settings/about', (_, __) => const AboutSettingsScreen()),

      // Modal-grade presentations: blurFade.
      _blurFadeRoute('/intelligence', (_, __) => const IntelligenceScreen()),
      _blurFadeRoute('/vault', (_, __) => const VaultScreen()),
      _route(
        '/vault/credential/:id',
        (_, state) => CredentialDetailScreen(
          credentialId: state.pathParameters['id'] ?? '',
        ),
      ),
      _blurFadeRoute(
        '/vault/issuance',
        (_, state) {
          final extra = state.extra;
          if (extra is Map<String, dynamic>) {
            return IssuanceScreen(
              title: (extra['title'] as String?) ?? 'Republic of Iceland · Passport',
              subtitle: (extra['subtitle'] as String?) ?? 'Bearer · GlobeID',
              issuer: (extra['issuer'] as String?) ?? 'Republic of Iceland',
              blockHeight: (extra['blockHeight'] as int?) ?? 12_148_337,
            );
          }
          return const IssuanceScreen(
            title: 'Republic of Iceland · Passport',
            subtitle: 'Bearer · GlobeID',
            issuer: 'Republic of Iceland',
            blockHeight: 12148337,
          );
        },
      ),
      _blurFadeRoute('/audit-log', (_, __) => const AuditLogScreen()),
      _blurFadeRoute('/inbox', (_, __) => const InboxScreen()),

      // Notifications/alerts/scanner overlays: drop.
      _dropRoute('/scan', (_, __) => const ScannerScreen()),
      _dropRoute('/copilot', (_, __) => const CopilotScreen()),
      // Copilot Hub — the consolidated view of every Copilot
      // recommendation currently in flight. Sits adjacent to the
      // chat surface, not in place of it.
      _route('/copilot/hub', (_, __) => const CopilotHubScreen()),

      // Altitude descent: kiosk → boarding → passport-live → trip detail.
      _descentRoute('/kiosk-sim', (_, __) => const KioskScreen()),
      _descentRoute('/passport-live', (_, __) => const PassportLiveScreen()),
      _descentRoute(
        '/boarding/:tripId/:legId',
        (_, state) => BoardingPassLiveScreen(
          tripId: state.pathParameters['tripId']!,
          legId: state.pathParameters['legId']!,
        ),
      ),
      _descentRoute(
        '/trip/:tripId',
        (_, state) => TripDetailScreen(tripId: state.pathParameters['tripId']!),
      ),

      // ─── Phase 4 — Live systems ────────────────────────────────────
      _descentRoute('/live', (_, __) => const LiveSystemsHubScreen()),
      _descentRoute(
        '/visa-live/:countryCode',
        (_, state) {
          final cc = state.pathParameters['countryCode']?.toUpperCase() ?? 'JP';
          final meta = _visaMetaFor(cc);
          return VisaLiveScreen(
            countryCode: cc,
            country: meta.$1,
            flag: meta.$2,
            tone: meta.$3,
          );
        },
      ),
      _descentRoute('/visa-live', (_, __) => const VisaLiveScreen()),
      _descentRoute('/forex-live', (_, __) => const ForexLiveScreen()),
      _descentRoute(
        '/trip-timeline-live',
        (_, __) => const TripTimelineLiveScreen(),
      ),
      _descentRoute(
        '/trip-timeline-live/:tripId',
        (_, state) =>
            TripTimelineLiveScreen(tripId: state.pathParameters['tripId']),
      ),
      _descentRoute(
        '/immigration-live',
        (_, __) => const ImmigrationLiveScreen(),
      ),
      _descentRoute(
        '/airport-companion-live',
        (_, __) => const AirportCompanionLiveScreen(),
      ),
      _descentRoute('/arrival-live', (_, __) => const ArrivalLiveScreen()),
      _descentRoute(
        '/transit-passes-live',
        (_, __) => const TransitPassesLiveScreen(),
      ),
      _descentRoute(
        '/lounge-live',
        (_, state) =>
            LoungeLiveScreen(loungeId: state.uri.queryParameters['id']),
      ),
      _descentRoute(
        '/lounge-live/:loungeId',
        (_, state) =>
            LoungeLiveScreen(loungeId: state.pathParameters['loungeId']),
      ),
      _descentRoute(
        '/country-live/:countryCode',
        (_, state) {
          final cc = state.pathParameters['countryCode']?.toUpperCase() ?? 'JP';
          final meta = _visaMetaFor(cc);
          return CountryIntelligenceLiveScreen(
            countryCode: cc,
            country: meta.$1,
            flag: meta.$2,
          );
        },
      ),
      _descentRoute(
        '/navigation-live',
        (_, __) => const NavigationLiveScreen(),
      ),

      // Default secondary surfaces: rise / slide-fade.
      _route('/receipt', (_, __) => const ReceiptScreen()),
      _route('/timeline', (_, __) => const TimelineScreen()),
      _route('/planner', (_, __) => const PlannerScreen()),
      _route('/social', (_, __) => const SocialScreen()),
      _route('/explore', (_, __) => const ExploreScreen()),
      _route('/passport-book', (_, __) => const PassportBookScreen()),
      _route('/feed', (_, __) => const FeedScreen()),
      _route('/multi-currency', (_, __) => const MultiCurrencyScreen()),
      _route(
          '/multi-currency-pour', (_, __) => const MultiCurrencyPourScreen()),
      _route('/analytics', (_, __) => const AnalyticsScreen()),
      GoRoute(
        path: '/pass/:passId',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          opaque: false,
          barrierColor: Colors.transparent,
          transitionDuration: Motion.dCruise,
          reverseTransitionDuration: Motion.dSheet,
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Motion.cStandard),
            child: child,
          ),
          child: PassDetailScreen(passId: state.pathParameters['passId']!),
        ),
      ),
      // Services sub-routes
      // Direct aliases so deep-links / nav from the new Nexus tiles
      // never hit "No route for /hotels" etc.
      GoRoute(path: '/hotels', redirect: (_, __) => '/services/hotels'),
      GoRoute(path: '/flights', redirect: (_, __) => '/services/flights'),
      GoRoute(path: '/restaurants', redirect: (_, __) => '/services/food'),
      GoRoute(path: '/transport', redirect: (_, __) => '/services/transport'),
      GoRoute(path: '/rides', redirect: (_, __) => '/services/rides'),
      GoRoute(path: '/activities', redirect: (_, __) => '/services/activities'),
      GoRoute(path: '/visa-scout', redirect: (_, __) => '/visa'),
      GoRoute(path: '/smart-routes', redirect: (_, __) => '/intelligence'),
      GoRoute(path: '/atlas', redirect: (_, __) => '/explore'),
      GoRoute(path: '/trip-pipeline', redirect: (_, __) => '/travel-os'),
      // Shortcut: `/boarding-pass-live` jumps straight to the live
      // boarding pass for whichever leg is most relevant right now.
      // BoardingPassLiveScreen auto-resolves to the first active /
      // upcoming leg when the requested IDs don't exist, so the
      // `auto/auto` sentinel is intentional and safe on fresh installs.
      GoRoute(
        path: '/boarding-pass-live',
        redirect: (_, __) => '/boarding/auto/auto',
      ),
      GoRoute(
        path: '/credential/:id',
        redirect: (_, state) =>
            '/visa?id=${state.pathParameters['id']}',
      ),
      _route('/services/hotels', (_, __) => const HotelsScreen()),
      _route(
        '/services/hotels/detail',
        (_, state) {
          final extra = state.extra;
          if (extra is HotelDetailArgs) {
            return HotelDetailScreen(
              hotelName: extra.hotelName,
              city: extra.city,
              country: extra.country,
              tonality: extra.tonality,
              rating: extra.rating,
              pricePerNight: extra.pricePerNight,
              flag: extra.flag,
            );
          }
          return const HotelDetailScreen(
            hotelName: 'Featured Hotel',
            city: 'San Francisco',
            country: 'United States',
            tonality: Color(0xFF7E22CE),
            rating: 4.7,
            pricePerNight: 320,
            flag: '🇺🇸',
          );
        },
      ),
      _route('/services/rides', (_, __) => const RidesScreen()),
      _route('/services/rides/live', (_, __) => const RideLiveScreen()),
      _route('/services/food', (_, __) => const FoodScreen()),
      _route(
        '/services/food/detail',
        (_, state) {
          final extra = state.extra;
          if (extra is RestaurantDetailArgs) {
            return RestaurantDetailScreen(
              name: extra.name,
              cuisine: extra.cuisine,
              city: extra.city,
              rating: extra.rating,
              tonality: extra.tonality,
              flag: extra.flag,
              priceTier: extra.priceTier,
            );
          }
          return const RestaurantDetailScreen(
            name: 'Featured Restaurant',
            cuisine: 'Omakase',
            city: 'Tokyo',
            rating: 4.8,
            tonality: Color(0xFFE11D48),
            flag: '🇯🇵',
            priceTier: 3,
          );
        },
      ),
      _route('/services/flights', (_, __) => const FlightsScreen()),
      _route('/services/activities', (_, __) => const ActivitiesScreen()),
      _route('/services/transport', (_, __) => const TransportScreen()),
      _route('/super-services', (_, __) => const SuperServicesScreen()),
      _route('/airport', (_, __) => const AirportScreen()),
      _route('/airport-mode', (_, __) => const AirportOrchestratorScreen()),
      _route('/trip-wallet', (_, __) => const TripWalletScreen()),
      _route('/travel-os', (_, __) => const TravelOSScreen()),
      _route('/arrival', (_, __) => const ArrivalWelcomeScreen()),
      _route('/sensors-lab', (_, __) => const SensorsLabScreen()),
      _route('/premium-showcase', (_, __) => const PremiumShowcaseScreen()),
      _route('/visa', (_, __) => const VisaDetailScreen()),
      // Visa renewal ceremony — the Copilot-launched cinematic flow.
      // Optional query: ?country=Schengen Area&days=11&flag=🇪🇺
      _sheetRoute(
        '/visa/renew',
        (_, state) {
          final q = state.uri.queryParameters;
          final country = q['country'];
          final flag = q['flag'];
          final daysRaw = q['days'];
          final days = daysRaw == null ? null : int.tryParse(daysRaw);
          final visaType = q['visaType'];
          return VisaRenewalCeremony(
            country: country ?? 'Schengen Area',
            flag: flag ?? '🇪🇺',
            daysToExpiry: days ?? 11,
            visaType: visaType ?? 'Schengen short-stay',
          );
        },
      ),
      _route('/lounge', (_, __) => const LoungeScreen()),
      _route('/esim', (_, __) => const EsimScreen()),
      _route('/phrasebook', (_, __) => const PhrasebookScreen()),
      _route('/emergency', (_, __) => const EmergencySosScreen()),
      _route('/itinerary', (_, __) => const ItineraryBuilderScreen()),
      _route('/country', (_, __) => const CountryProfileScreen()),
      _route('/packing', (_, __) => const PackingChecklistScreen()),
      _route('/customs', (_, __) => const CustomsDeclarationScreen()),
      _route('/journal', (_, __) => const TripJournalScreen()),
      // Wallet flows + ledger sub-surfaces present as Apple-grade
      // sheets — slide up from the bottom on a soft spring, light
      // scale on the previous content. Matches user intuition that
      // these are temporary surfaces. See `_sheetRoute`.
      _sheetRoute(
        '/wallet/send',
        (_, __) => const WalletFlowScreen(flow: WalletFlow.send),
      ),
      _sheetRoute(
        '/wallet/receive',
        (_, __) => const WalletFlowScreen(flow: WalletFlow.receive),
      ),
      _sheetRoute(
        '/wallet/scan',
        (_, __) => const WalletFlowScreen(flow: WalletFlow.scanPay),
      ),
      _sheetRoute(
        '/wallet/exchange',
        (_, __) => const WalletFlowScreen(flow: WalletFlow.exchange),
      ),
      _sheetRoute(
        '/wallet/scheduled',
        (_, __) => const WalletScheduledScreen(),
      ),
      _sheetRoute(
        '/wallet/statements',
        (_, __) => const WalletStatementsScreen(),
      ),
      // OS2 screens — cinematic primary surfaces.
      _route('/os2/onboarding', (_, __) => const Os2OnboardingScreen()),
      _route('/os2/lock', (_, __) => const Os2LockScreen()),
      _route('/os2/airport', (_, __) => const Os2AirportOrchestrator()),
      _route('/os2/boarding', (_, __) => const Os2BoardingPassScreen()),
      _route('/os2/copilot', (_, __) => const Os2CopilotScreen()),
      _route('/os2/settings', (_, __) => const Os2SettingsScreen()),
      _route('/os2/passport', (_, __) => const Os2PassportBookScreen()),
      _route('/os2/treasury', (_, __) => const Os2TreasuryHub()),
      _route('/os2/trust', (_, __) => const Os2TrustHub()),
      _route('/os2/concierge', (_, __) => const Os2ConciergeHub()),
      // Nexus screens — the canonical Travel OS / Wallet / Passport.
      _route('/nexus/os', (_, __) => const NexusTravelOsScreen()),
      _route('/nexus/wallet', (_, __) => const NexusWalletScreen()),
      _route('/nexus/passport', (_, __) => const NexusPassportScreen()),
      // Bible screens — the liquid-glass cinematic operating system.
      _route('/bible/lock', (_, __) => const BibleLockScreen()),
      _route('/bible/home', (_, __) => const BibleHomeScreen()),
      _route('/bible/passport', (_, __) => const BiblePassportScreen()),
      _route('/bible/wallet', (_, __) => const BibleWalletScreen()),
      _route('/bible/boarding', (_, __) => const BibleBoardingScreen()),
      _route('/bible/arrival', (_, __) => const BibleArrivalScreen()),
      _route('/bible/lounge', (_, __) => const BibleLoungeScreen()),
      _route('/bible/trip', (_, __) => const BibleTripScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text('No route for ${state.uri}')),
    ),
  );
});

/// Country metadata (name, flag, visa-tone) for Live Visa / Country
/// Intelligence routes. Keeps the route layer free of import cycles.
(String, String, Color) _visaMetaFor(String cc) {
  switch (cc.toUpperCase()) {
    case 'JP':
      return ('Japan', '🇯🇵', const Color(0xFFE11D48));
    case 'US':
      return ('United States', '🇺🇸', const Color(0xFF1E3A8A));
    case 'GB':
      return ('United Kingdom', '🇬🇧', const Color(0xFF7C3AED));
    case 'AE':
      return ('United Arab Emirates', '🇦🇪', const Color(0xFF14B8A6));
    case 'IN':
      return ('India', '🇮🇳', const Color(0xFFF59E0B));
    case 'FR':
      return ('France', '🇫🇷', const Color(0xFF6366F1));
    case 'IT':
      return ('Italy', '🇮🇹', const Color(0xFF10B981));
    case 'ES':
      return ('Spain', '🇪🇸', const Color(0xFFEF4444));
    case 'SG':
      return ('Singapore', '🇸🇬', const Color(0xFFEC4899));
    case 'TH':
      return ('Thailand', '🇹🇭', const Color(0xFF8B5CF6));
    default:
      return ('Japan', '🇯🇵', const Color(0xFFE11D48));
  }
}
