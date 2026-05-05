import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';

import 'app/app_boot.dart';
import 'app/router.dart';
import 'app/theme/app_theme.dart';
import 'features/settings/theme_prefs_provider.dart';

/// GlobeID Flutter — entry point.
///
/// Mirrors `src/main.tsx` + `src/App.tsx` boot sequence:
/// 1. Apply theme prefs (read from SharedPreferences before first frame).
/// 2. Hydrate Riverpod stores from persisted snapshots.
/// 3. Wire deep-link / lifecycle / network listeners (handled inside [GlobeIdApp]).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  await AppBoot.bootstrap();
  runApp(const ProviderScope(child: GlobeIdApp()));
}

class GlobeIdApp extends ConsumerWidget {
  const GlobeIdApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(themePrefsProvider);
    final router = ref.watch(routerProvider);
    return ToastificationWrapper(
      child: MaterialApp.router(
        title: 'GlobeID',
        debugShowCheckedModeBanner: false,
        themeMode: prefs.themeMode,
        theme: AppTheme.light(prefs),
        darkTheme: AppTheme.dark(prefs),
        routerConfig: router,
      ),
    );
  }
}
