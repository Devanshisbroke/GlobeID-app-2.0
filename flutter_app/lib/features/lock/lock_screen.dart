import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../app/theme/app_tokens.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _auth = LocalAuthentication();
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock GlobeID',
      );
      if (ok && mounted) context.go('/');
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space7),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded,
                  size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: AppTokens.space5),
              Text('GlobeID', style: theme.textTheme.headlineLarge),
              if (_error != null) ...[
                const SizedBox(height: AppTokens.space3),
                Text(_error!,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: AppTokens.space7),
              FilledButton.icon(
                onPressed: _unlock,
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
