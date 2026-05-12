import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/premium/premium.dart';
import '../../widgets/pressable.dart';
import 'onboarding_provider.dart';

/// Cinematic onboarding — full-bleed brand canvas, animated planet
/// glyph that morphs per-page, deep accent gradients, glassy footer
/// with morphing CTA.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final _ctrl = PageController();
  int _i = 0;

  late final _orbit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 12000),
  )..repeat();

  static const _slides = <_Slide>[
    _Slide(
      'Travel super-app',
      'Wallet, identity, scanner, planner — one premium experience.',
      Icons.public_rounded,
      Color(0xFF7C3AED),
      Color(0xFF06B6D4),
      [
        ('Globe', Icons.public_rounded),
        ('Wallet', Icons.account_balance_wallet_rounded),
        ('Identity', Icons.fingerprint_rounded),
        ('Travel', Icons.flight_takeoff_rounded),
      ],
    ),
    _Slide(
      'Boarding-ready',
      'Apple/Google-Wallet-grade boarding passes with real HMAC signing.',
      Icons.confirmation_num_rounded,
      Color(0xFF06B6D4),
      Color(0xFF10B981),
      [
        ('Stack peek', Icons.layers_rounded),
        ('Brightness ramp', Icons.brightness_high_rounded),
        ('Live MRZ scan', Icons.qr_code_scanner_rounded),
        ('HMAC verify', Icons.lock_rounded),
      ],
    ),
    _Slide(
      'Deterministic copilot',
      'Local-first intelligence. No hallucinations.',
      Icons.smart_toy_rounded,
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      [
        ('Streamed replies', Icons.bolt_rounded),
        ('Travel intel', Icons.flight_rounded),
        ('Wallet intel', Icons.attach_money_rounded),
        ('Identity intel', Icons.verified_user_rounded),
      ],
    ),
    _Slide(
      'Worldwide wallet',
      'Hold balances in any currency. Auto-FX. Spend caps. Real receipts.',
      Icons.account_balance_wallet_rounded,
      Color(0xFFEC4899),
      Color(0xFF7C3AED),
      [
        ('Multi-currency', Icons.currency_exchange_rounded),
        ('Spend caps', Icons.shield_rounded),
        ('Receipts', Icons.receipt_long_rounded),
        ('Insights', Icons.insights_rounded),
      ],
    ),
    _Slide(
      'Yours, secured',
      'Biometric vault, audit log, reduce-transparency.',
      Icons.shield_rounded,
      Color(0xFFF59E0B),
      Color(0xFF7C3AED),
      [
        ('Biometric lock', Icons.fingerprint_rounded),
        ('Audit log', Icons.history_rounded),
        ('Reduced motion', Icons.accessibility_new_rounded),
        ('Local-first', Icons.cloud_off_rounded),
      ],
    ),
    _Slide(
      'Passport ingest',
      'Snap your passport. We extract MRZ on-device, never on a server.',
      Icons.qr_code_scanner_rounded,
      Color(0xFF06B6D4),
      Color(0xFF7C3AED),
      [
        ('On-device OCR', Icons.remove_red_eye_rounded),
        ('MRZ verify', Icons.verified_rounded),
        ('Holographic foil', Icons.auto_awesome_rounded),
        ('Tier upgrade', Icons.workspace_premium_rounded),
      ],
    ),
    _Slide(
      'Biometric verify',
      'Face + fingerprint binding. Hardware-backed where available.',
      Icons.fingerprint_rounded,
      Color(0xFFD4AF37),
      Color(0xFFEA580C),
      [
        ('Face ID / Touch ID', Icons.face_rounded),
        ('Hardware keystore', Icons.memory_rounded),
        ('Liveness check', Icons.visibility_rounded),
        ('Recovery codes', Icons.vpn_key_rounded),
      ],
    ),
    _Slide(
      'Vault setup',
      'A private, end-to-end-encrypted home for documents and credentials.',
      Icons.lock_rounded,
      Color(0xFF7C3AED),
      Color(0xFF06B6D4),
      [
        ('E2E encryption', Icons.shield_moon_rounded),
        ('Auto-organize', Icons.folder_special_rounded),
        ('Cross-device sync', Icons.devices_rounded),
        ('Selective share', Icons.share_rounded),
      ],
    ),
    _Slide(
      'Payment method',
      'Add a card to unlock concierge bookings, lounge access, eSIM data.',
      Icons.credit_card_rounded,
      Color(0xFF10B981),
      Color(0xFF06B6D4),
      [
        ('Apple Pay / Google Pay', Icons.payment_rounded),
        ('Multi-currency wallet', Icons.currency_exchange_rounded),
        ('Spend caps', Icons.shield_rounded),
        ('Receipts auto-saved', Icons.receipt_long_rounded),
      ],
    ),
    _Slide(
      'Network verification',
      'Cross-check your identity against trusted issuers worldwide.',
      Icons.hub_rounded,
      Color(0xFF3B82F6),
      Color(0xFF7C3AED),
      [
        ('Issuer network', Icons.public_rounded),
        ('Score boost', Icons.trending_up_rounded),
        ('Anti-fraud', Icons.security_rounded),
        ('Tier unlocks', Icons.star_rounded),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _orbit.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    await ref.read(onboardingProvider.notifier).complete();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = _slides[_i];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.4,
                colors: [
                  s.start.withValues(alpha: 0.45),
                  Colors.black,
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _orbit,
            builder: (_, __) => Positioned(
              top: 120,
              left: 40 + 60 * math.sin(_orbit.value * 2 * math.pi),
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      s.end.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _ctrl,
                    onPageChanged: (i) {
                      HapticFeedback.selectionClick();
                      setState(() => _i = i);
                    },
                    itemCount: _slides.length,
                    itemBuilder: (_, i) {
                      final slide = _slides[i];
                      return Padding(
                        padding: const EdgeInsets.all(AppTokens.space7),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedAppearance(
                              key: ValueKey('icon-$i'),
                              child: SensorPendulum(
                                translation: 5,
                                rotation: 0.025,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [slide.start, slide.end],
                                    ),
                                    boxShadow:
                                        AppTokens.shadowLg(tint: slide.start),
                                  ),
                                  child: Icon(slide.icon,
                                      size: 64, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTokens.space7),
                            AnimatedAppearance(
                              key: ValueKey('title-$i'),
                              delay: const Duration(milliseconds: 120),
                              child: Text(
                                slide.title,
                                style: theme.textTheme.displayMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: AppTokens.space3),
                            AnimatedAppearance(
                              key: ValueKey('msg-$i'),
                              delay: const Duration(milliseconds: 200),
                              child: Text(
                                slide.message,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: AppTokens.space5),
                            AnimatedAppearance(
                              key: ValueKey('feat-$i'),
                              delay: const Duration(milliseconds: 280),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  for (final f in slide.features)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          AppTokens.radiusFull,
                                        ),
                                        color: Colors.white.withValues(
                                          alpha: 0.10,
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.18,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            f.$2,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            f.$1,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var d = 0; d < _slides.length; d++)
                      AnimatedContainer(
                        duration: AppTokens.durationSm,
                        width: d == _i ? 26 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: d == _i
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTokens.space5),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.space5,
                    0,
                    AppTokens.space5,
                    AppTokens.space5,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _finish,
                          style: TextButton.styleFrom(
                            foregroundColor:
                                Colors.white.withValues(alpha: 0.7),
                          ),
                          child: const Text('Skip'),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Pressable(
                          scale: 0.96,
                          onTap: () {
                            if (_i < _slides.length - 1) {
                              _ctrl.nextPage(
                                duration: AppTokens.durationLg,
                                curve: AppTokens.easeOutSoft,
                              );
                            } else {
                              _finish();
                            }
                          },
                          child: Container(
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppTokens.radiusFull),
                              gradient: LinearGradient(
                                colors: [s.start, s.end],
                              ),
                              boxShadow: AppTokens.shadowLg(tint: s.start),
                            ),
                            child: Text(
                              _i < _slides.length - 1
                                  ? 'Continue'
                                  : 'Get started',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  const _Slide(
    this.title,
    this.message,
    this.icon,
    this.start,
    this.end,
    this.features,
  );
  final String title;
  final String message;
  final IconData icon;
  final Color start;
  final Color end;
  final List<(String, IconData)> features;
}
