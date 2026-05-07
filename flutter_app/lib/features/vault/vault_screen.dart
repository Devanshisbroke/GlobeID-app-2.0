import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/models/travel_document.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/section_header.dart';
import '../user/user_provider.dart';

/// Premium vault — biometric gate, document grid with brand color
/// chips, expiry meter, copy-to-clipboard quick action.
class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});
  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen>
    with SingleTickerProviderStateMixin {
  final _auth = LocalAuthentication();
  bool _unlocked = false;
  bool _busy = false;
  String? _error;

  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock vault',
        options:
            const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (ok) HapticFeedback.mediumImpact();
      if (mounted) setState(() => _unlocked = ok);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final theme = Theme.of(context);

    if (!_unlocked) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.space7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, __) => SizedBox(
                      width: 200,
                      height: 200,
                      child: CustomPaint(
                        isComplex: true,
                        willChange: true,
                        painter: _LockPulse(
                          progress: _pulse.value,
                          color: theme.colorScheme.primary,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.shield_moon_rounded,
                            size: 64,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.space7),
                AnimatedAppearance(
                  child: Text('Vault locked',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
                ),
                const SizedBox(height: AppTokens.space2),
                AnimatedAppearance(
                  delay: const Duration(milliseconds: 80),
                  child: Text(
                    _error ?? 'Use Face ID, Touch ID, or your device passcode.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppTokens.space7),
                AnimatedAppearance(
                  delay: const Duration(milliseconds: 200),
                  child: Pressable(
                    scale: 0.96,
                    onTap: _unlock,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 36, vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusFull),
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.6),
                          ],
                        ),
                        boxShadow:
                            AppTokens.shadowLg(tint: theme.colorScheme.primary),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.fingerprint_rounded,
                              color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            _busy ? 'Authenticating…' : 'Unlock vault',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PageScaffold(
      title: 'Vault',
      subtitle: '${user.documents.length} secure documents',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          if (user.documents.isEmpty)
            const EmptyState(
              title: 'No documents yet',
              message:
                  'Add a passport, visa, or boarding pass to keep it secure.',
              icon: Icons.shield_outlined,
            )
          else ...[
            const SectionHeader(title: 'Documents', dense: true),
            for (var i = 0; i < user.documents.length; i++)
              AnimatedAppearance(
                delay: Duration(milliseconds: 60 * i),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.space3),
                  child: _VaultDocCard(doc: user.documents[i]),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _LockPulse extends CustomPainter {
  _LockPulse({required this.progress, required this.color});
  final double progress;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final base = math.min(size.width, size.height) / 2 - 16;
    for (var i = 0; i < 3; i++) {
      final p = ((progress + i / 3) % 1.0);
      final r = base * (0.5 + p * 0.5);
      final paint = Paint()
        ..color = color.withValues(alpha: (1 - p) * 0.32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(c, r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LockPulse old) => old.progress != progress;
}

class _VaultDocCard extends StatelessWidget {
  const _VaultDocCard({required this.doc});
  final TravelDocument doc;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final daysToExpiry = _daysToExpiry(doc.expiryDate);
    final expiringSoon = daysToExpiry != null && daysToExpiry < 90;
    return Pressable(
      scale: 0.99,
      onTap: () {
        HapticFeedback.lightImpact();
      },
      child: PremiumCard(
        padding: const EdgeInsets.all(AppTokens.space5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.10),
            accent.withValues(alpha: 0.02),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                  ),
                  child: Icon(_iconFor(doc.type), color: accent, size: 22),
                ),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc.label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                      Text('${doc.countryFlag} ${doc.country}',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                _StatusChip(status: doc.status),
              ],
            ),
            const SizedBox(height: AppTokens.space4),
            Row(
              children: [
                Icon(Icons.event_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text('Expires ${doc.expiryDate}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    )),
                const Spacer(),
                if (daysToExpiry != null)
                  Text(
                    expiringSoon ? 'Renew soon' : '$daysToExpiry days left',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: expiringSoon
                          ? const Color(0xFFEF4444)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'boarding_pass':
        return Icons.confirmation_number_rounded;
      case 'visa':
        return Icons.travel_explore_rounded;
      case 'passport':
        return Icons.menu_book_rounded;
      default:
        return Icons.badge_rounded;
    }
  }

  int? _daysToExpiry(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return null;
    return d.difference(DateTime.now()).inDays;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOk = status.toLowerCase().contains('valid') ||
        status.toLowerCase().contains('active');
    final color = isOk ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        status,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
