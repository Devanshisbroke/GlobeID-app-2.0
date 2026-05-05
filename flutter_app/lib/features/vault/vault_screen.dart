import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/section_header.dart';
import '../user/user_provider.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});
  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  final _auth = LocalAuthentication();
  bool _unlocked = false;
  String? _error;

  Future<void> _unlock() async {
    setState(() => _error = null);
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock vault',
        options:
            const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (mounted) setState(() => _unlocked = ok);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (!_unlocked) {
      return PageScaffold(
        title: 'Vault',
        subtitle: 'Biometric protected',
        body: EmptyState(
          title: 'Vault locked',
          message: _error ?? 'Use Face ID, Touch ID, or your device passcode.',
          icon: Icons.lock_rounded,
          cta: 'Unlock',
          onCta: _unlock,
        ),
      );
    }

    return PageScaffold(
      title: 'Vault',
      subtitle: '${user.documents.length} secure documents',
      body: ListView(
        children: [
          const SectionHeader(title: 'Documents', dense: true),
          for (final d in user.documents)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.space2),
              child: GlassSurface(
                child: Row(
                  children: [
                    Icon(Icons.shield_rounded,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: AppTokens.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.label),
                          Text('${d.country} · expires ${d.expiryDate}',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
