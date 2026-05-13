import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';

import 'app/app_boot.dart';
import 'app/deep_link_controller.dart';
import 'app/router.dart';
import 'app/theme/app_theme.dart';
import 'core/performance_overlay.dart';
import 'features/settings/theme_prefs_provider.dart';
import 'widgets/inline_error_widget.dart';

/// GlobeID Flutter — entry point.
///
/// Mirrors `src/main.tsx` + `src/App.tsx` boot sequence:
/// 1. Apply theme prefs (read from SharedPreferences before first frame).
/// 2. Hydrate Riverpod stores from persisted snapshots.
/// 3. Wire deep-link / lifecycle / network listeners (handled inside [GlobeIdApp]).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ─── 120Hz / 90Hz refresh-rate opt-in (Android) ──────────────────
  //
  // Flutter on Android picks the lowest "preferred" refresh rate by
  // default — even on 120Hz panels — to save battery. We explicitly
  // opt into the highest supported rate so every animation, scroll,
  // and page transition runs on the panel's native cadence (8.3ms
  // frame budget at 120Hz, 11.1ms at 90Hz). iOS ProMotion devices
  // are already handled automatically by Flutter 3.10+.
  //
  // Wrapped in try/catch because some Android devices (older or
  // non-OEM ROMs) return a null active mode; we never want to crash
  // boot on a display-mode query.
  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (_) {
      // Falls back to system default — no jank, just 60Hz.
    }
  }
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  // Replace Flutter's default red-box ErrorWidget with a compact,
  // theme-aware inline diagnostic so a single broken sub-tree never
  // blanks an entire screen. See widgets/inline_error_widget.dart.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return InlineErrorWidget(details: details);
  };

  // Mirror Flutter framework errors to console so we can surface
  // paint-phase exceptions during development / web profile builds.
  final defaultOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    defaultOnError?.call(details);
    if (kDebugMode || kProfileMode) {
      // ignore: avoid_print
      print('▶▶ FlutterError: ${details.exceptionAsString()}');
      // ignore: avoid_print
      print('   library: ${details.library}');
      if (details.context != null) {
        // ignore: avoid_print
        print('   context: ${details.context}');
      }
    }
  };
  await AppBoot.bootstrap();
  // Frame-timing FPS sampler — only active in debug mode.
  PerformanceMonitor.instance.start();
  runApp(const ProviderScope(child: GlobeIdApp()));
}

class GlobeIdApp extends ConsumerWidget {
  const GlobeIdApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(themePrefsProvider);
    final router = ref.watch(routerProvider);
    return DeepLinkController(
      router: router,
      child: ToastificationWrapper(
        child: MaterialApp.router(
          title: 'GlobeID',
          debugShowCheckedModeBanner: false,
          themeMode: prefs.themeMode,
          theme: AppTheme.light(prefs),
          darkTheme: AppTheme.dark(prefs),
          routerConfig: router,
          // Premium iOS-style bouncing scroll across all platforms,
          // so every list / page in the app reads as buttery-smooth
          // regardless of underlying device chassis.
          scrollBehavior: const _GlobeScrollBehavior(),
        ),
      ),
    );
  }
}

/// Premium scroll behavior — bouncing physics + clean drag devices.
/// Pinned at app level so every Scrollable / ListView / CustomScrollView
/// inherits the same iOS-style buttery momentum.
class _GlobeScrollBehavior extends ScrollBehavior {
  const _GlobeScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      decelerationRate: ScrollDecelerationRate.fast,
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Suppress Android's green glow overscroll — bouncing already
    // gives the affordance.
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
      };
}
