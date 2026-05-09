import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Bridges the platform deep-link plumbing into the app's router so the
/// same paths the bottom nav / hub uses can be reached from outside the
/// app (notifications, marketing emails, OS-level URL handlers).
///
/// Supported schemes:
///   `globeid://<host>[/<id>]` where host is one of:
///     - trip / pass / scan / wallet (legacy)
///     - identity / vault / map / travel / services
///     - airport / airport-mode / arrival / boarding
///     - super-services / globe / passport-live / passport-book
///     - visa / customs / packing / phrasebook / emergency
///     - planner / copilot / discover / inbox / settings
class DeepLinkController extends ConsumerStatefulWidget {
  const DeepLinkController({
    super.key,
    required this.router,
    required this.child,
  });

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<DeepLinkController> createState() => _DeepLinkControllerState();
}

class _DeepLinkControllerState extends ConsumerState<DeepLinkController> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final initial = await _appLinks.getInitialLink();
    if (!mounted) return;
    if (initial != null) _route(initial);
    _sub = _appLinks.uriLinkStream.listen(_route);
  }

  void _route(Uri uri) {
    final target = _targetFor(uri);
    if (target == null || !mounted) return;
    widget.router.push(target);
  }

  String? _targetFor(Uri uri) {
    if (uri.scheme != 'globeid') return null;
    final segments = [
      if (uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments.where((s) => s.isNotEmpty),
    ];
    if (segments.isEmpty) return null;
    final head = segments.first;
    final tail = segments.skip(1).map(Uri.encodeComponent).toList();

    // Routes that take a single id/path segment.
    String? withId(String prefix) =>
        tail.isNotEmpty ? '$prefix/${tail.join('/')}' : null;

    return switch (head) {
      // Existing legacy targets (kept for backward compatibility).
      'trip' => withId('/trip'),
      'pass' => withId('/pass'),
      'boarding' when tail.length >= 2 => '/boarding/${tail[0]}/${tail[1]}',
      'scan' => '/scan',
      'wallet' when tail.isEmpty => '/wallet',
      'wallet' when tail.first == 'send' => '/wallet/send',
      'wallet' when tail.first == 'receive' => '/wallet/receive',
      'wallet' when tail.first == 'scan' => '/wallet/scan',
      'wallet' when tail.first == 'exchange' => '/wallet/exchange',

      // Core hubs.
      'home' => '/',
      'identity' => '/identity',
      'travel' => '/travel',
      'services' when tail.isEmpty => '/services',
      'services' => '/services/${tail.join('/')}',
      'map' => '/map',

      // Wallet & money.
      'multi-currency' => '/multi-currency',
      'multi-currency-pour' => '/multi-currency-pour',
      'trip-wallet' => '/trip-wallet',

      // Identity / security.
      'vault' => '/vault',
      'audit-log' => '/audit-log',
      'visa' => '/visa',
      'lock' => '/lock',

      // Travel orchestration.
      'airport' => '/airport',
      'airport-mode' => '/airport-mode',
      'arrival' => '/arrival',
      'travel-os' => '/travel-os',
      'super-services' => '/super-services',
      'planner' => '/planner',
      'itinerary' => '/itinerary',
      'country' => '/country',
      'packing' => '/packing',
      'customs' => '/customs',
      'phrasebook' => '/phrasebook',
      'emergency' => '/emergency',
      'journal' => '/journal',
      'esim' => '/esim',
      'lounge' => '/lounge',

      // Cinematic systems.
      'globe' || 'globe-cinematic' => '/globe-cinematic',
      'passport-live' => '/passport-live',
      'passport-book' => '/passport-book',
      'sensors-lab' => '/sensors-lab',
      'premium-showcase' => '/premium-showcase',
      'kiosk-sim' => '/kiosk-sim',

      // Discovery & social.
      'discover' => '/discover',
      'explore' => '/explore',
      'feed' => '/feed',
      'social' => '/social',
      'timeline' => '/timeline',
      'inbox' => '/inbox',
      'copilot' => '/copilot',

      // Settings.
      'settings' when tail.isEmpty => '/settings',
      'settings' => '/settings/${tail.join('/')}',
      _ => null,
    };
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
