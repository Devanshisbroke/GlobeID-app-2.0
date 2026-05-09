import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/models/travel_document.dart';
import '../../domain/airline_brand.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/premium_effects.dart';
import '../../widgets/pressable.dart';
import '../user/user_provider.dart';

/// Full-screen, immersive pass detail. Drag-to-dismiss, brand-tinted
/// canvas, parallax tilt, QR with white plate, support details.
class PassDetailScreen extends ConsumerStatefulWidget {
  const PassDetailScreen({super.key, required this.passId});
  final String passId;

  @override
  ConsumerState<PassDetailScreen> createState() => _PassDetailScreenState();
}

class _PassDetailScreenState extends ConsumerState<PassDetailScreen> {
  double _drag = 0;
  double _tiltX = 0, _tiltY = 0;
  bool _qrBoost = false;

  // Wrapped in `handleError` so platforms without an accelerometer
  // (desktop, web, some emulators) silently fall back to flat instead
  // of spamming uncaught errors.
  late final Stream<AccelerometerEvent> _accel = accelerometerEventStream(
    samplingPeriod: const Duration(milliseconds: 50),
  ).handleError((_) {});

  @override
  void initState() {
    super.initState();
    // Make sure status bar is light over the dark hero canvas.
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final pass = user.documents.cast<TravelDocument?>().firstWhere(
          (d) => d?.id == widget.passId,
          orElse: () => null,
        );

    if (pass == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.confirmation_number_outlined,
                  color: Colors.white54, size: 56),
              const SizedBox(height: AppTokens.space3),
              Text('Pass not found',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: Colors.white)),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    final brand = resolveAirlineBrand(pass.label);
    final dragPct = (_drag / 320).clamp(0.0, 1.0);

    return GestureDetector(
      onVerticalDragUpdate: (d) {
        if (d.delta.dy > 0) setState(() => _drag = (_drag + d.delta.dy));
      },
      onVerticalDragEnd: (_) {
        if (_drag > 140) {
          HapticFeedback.lightImpact();
          Navigator.of(context).maybePop();
        } else {
          setState(() => _drag = 0);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Brand backdrop — dimmed by drag progress.
            Positioned.fill(
              child: AnimatedContainer(
                duration: AppTokens.durationXs,
                color: Color.lerp(
                  Colors.black,
                  brand.primary.withValues(alpha: 0.6),
                  1 - dragPct,
                )!,
                child: const _NoiseField(),
              ),
            ),
            // QR boost veil — simulates Apple Wallet's brightness boost
            // when the QR is presented for scanning.
            AnimatedOpacity(
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              opacity: _qrBoost ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_qrBoost,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _qrBoost = false);
                  },
                  child: Container(color: Colors.white),
                ),
              ),
            ),
            // Giant boost-mode QR overlay (above the white veil).
            if (_qrBoost)
              Positioned.fill(
                child: SafeArea(
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _qrBoost = false);
                      },
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        tween: Tween(begin: 0, end: 1),
                        builder: (_, v, child) => Opacity(
                          opacity: v,
                          child: Transform.scale(
                            scale: 0.92 + 0.08 * v,
                            child: child,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.circular(AppTokens.radius2xl),
                                boxShadow: [
                                  BoxShadow(
                                    color: brand.primary
                                        .withValues(alpha: 0.18),
                                    blurRadius: 30,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data: pass.number,
                                size: 280,
                                backgroundColor: Colors.white,
                                eyeStyle: QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: brand.primary,
                                ),
                                dataModuleStyle: QrDataModuleStyle(
                                  dataModuleShape:
                                      QrDataModuleShape.square,
                                  color: brand.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTokens.space4),
                            Text(
                              pass.number,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: AppTokens.space2),
                            Text(
                              'Tap anywhere to dim',
                              style: TextStyle(
                                color: Colors.black.withValues(alpha: 0.55),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                    AppTokens.space5, 0, AppTokens.space5, AppTokens.space7),
                child: Column(
                  children: [
                    _Header(
                      onClose: () => Navigator.of(context).maybePop(),
                      title: pass.label,
                      onBoost: () {
                        HapticFeedback.mediumImpact();
                        setState(() => _qrBoost = true);
                      },
                    ),
                    const SizedBox(height: AppTokens.space6),
                    StreamBuilder<AccelerometerEvent>(
                      stream: _accel,
                      builder: (_, snap) {
                        if (snap.hasData) {
                          final e = snap.data!;
                          _tiltX = (e.y.clamp(-3, 3) / 3) * (math.pi / 18);
                          _tiltY = (e.x.clamp(-3, 3) / 3) * (math.pi / 18);
                        }
                        return Hero(
                          tag: 'pass-${pass.id}',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Transform.translate(
                              offset: Offset(0, _drag * 0.4),
                              child: Transform(
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateX(_tiltX)
                                  ..rotateY(_tiltY),
                                alignment: Alignment.center,
                                child: TiltShimmer(
                                  borderRadius: BorderRadius.circular(
                                      AppTokens.radius3xl),
                                  child: _ImmersivePass(
                                    pass: pass,
                                    brand: brand,
                                    onQrTap: () {
                                      HapticFeedback.mediumImpact();
                                      setState(() => _qrBoost = true);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppTokens.space5),
                    AnimatedAppearance(
                      delay: const Duration(milliseconds: 100),
                      child: _SupportPanel(pass: pass, brand: brand),
                    ),
                    const SizedBox(height: AppTokens.space4),
                    AnimatedAppearance(
                      delay: const Duration(milliseconds: 160),
                      child: _ActionsRow(brand: brand),
                    ),
                    const SizedBox(height: AppTokens.space4),
                    AnimatedAppearance(
                      delay: const Duration(milliseconds: 200),
                      child: _ActivityCard(brand: brand),
                    ),
                    const SizedBox(height: AppTokens.space4),
                    AnimatedAppearance(
                      delay: const Duration(milliseconds: 240),
                      child: Text(
                        'Pull down to close · tap QR to boost',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.5),
                                letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    super.dispose();
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onClose,
    required this.title,
    required this.onBoost,
  });
  final VoidCallback onClose;
  final VoidCallback onBoost;
  final String title;

  Widget _chromeButton(IconData icon, VoidCallback onTap) {
    return Pressable(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(AppTokens.space2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
      child: Row(
        children: [
          _chromeButton(Icons.close_rounded, onClose),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _chromeButton(Icons.brightness_high_rounded, onBoost),
          const SizedBox(width: AppTokens.space2),
          _chromeButton(
              Icons.share_rounded, () => HapticFeedback.lightImpact()),
        ],
      ),
    );
  }
}

class _ImmersivePass extends StatelessWidget {
  const _ImmersivePass({
    required this.pass,
    required this.brand,
    this.onQrTap,
  });
  final TravelDocument pass;
  final AirlineBrand brand;
  final VoidCallback? onQrTap;

  @override
  Widget build(BuildContext context) {
    final iata = pass.label.length >= 3
        ? pass.label.substring(0, 3).toUpperCase()
        : 'GID';
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radius3xl),
      child: Container(
        decoration: BoxDecoration(
          gradient: brand.gradient(),
          boxShadow: [
            BoxShadow(
              color: brand.primary.withValues(alpha: 0.5),
              blurRadius: 60,
              offset: const Offset(0, 30),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppTokens.space6),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  pass.label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const Spacer(),
                Text(pass.countryFlag, style: const TextStyle(fontSize: 28)),
              ],
            ),
            const SizedBox(height: AppTokens.space5),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _IataBlock(code: iata),
                const Spacer(),
                Icon(Icons.flight,
                    color: Colors.white.withValues(alpha: 0.85), size: 28),
                const Spacer(),
                Text(pass.countryFlag, style: const TextStyle(fontSize: 36)),
              ],
            ),
            const SizedBox(height: AppTokens.space5),
            Pressable(
              scale: 0.97,
              onTap: onQrTap,
              child: Container(
                padding: const EdgeInsets.all(AppTokens.space3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTokens.radiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: pass.number,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: brand.primary,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: brand.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space4),
            Row(
              children: [
                Expanded(
                  child: _MetaCol(
                    label: 'Passenger',
                    value: pass.number,
                  ),
                ),
                Expanded(
                  child: _MetaCol(
                    label: 'Departs',
                    value: pass.issueDate,
                  ),
                ),
                Expanded(
                  child: _MetaCol(
                    label: 'Status',
                    value: pass.status,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IataBlock extends StatelessWidget {
  const _IataBlock({required this.code});
  final String code;
  @override
  Widget build(BuildContext context) {
    return Text(
      code,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _MetaCol extends StatelessWidget {
  const _MetaCol({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _SupportPanel extends StatelessWidget {
  const _SupportPanel({required this.pass, required this.brand});
  final TravelDocument pass;
  final AirlineBrand brand;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radius2xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(AppTokens.space4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTokens.radius2xl),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _PanelItem(
                  label: 'Reference',
                  value: pass.number,
                  icon: Icons.tag_rounded,
                ),
              ),
              Container(
                  width: 1,
                  height: 32,
                  color: Colors.white.withValues(alpha: 0.10)),
              Expanded(
                child: _PanelItem(
                  label: 'Issued',
                  value: pass.issueDate,
                  icon: Icons.calendar_today_rounded,
                ),
              ),
              Container(
                  width: 1,
                  height: 32,
                  color: Colors.white.withValues(alpha: 0.10)),
              Expanded(
                child: _PanelItem(
                  label: 'Country',
                  value: pass.country,
                  icon: Icons.public_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelItem extends StatelessWidget {
  const _PanelItem(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.65), size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Wallet-style action row: Add to wallet · Share · Boarding lookup ·
/// Get directions. Each tile is a frosted square with brand-tint
/// glyph + label.
class _ActionsRow extends StatelessWidget {
  const _ActionsRow({required this.brand});
  final AirlineBrand brand;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final a in const [
          (Icons.wallet_rounded, 'Add to Wallet'),
          (Icons.ios_share_rounded, 'Share'),
          (Icons.alt_route_rounded, 'Lookup'),
          (Icons.directions_rounded, 'Directions'),
        ])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Pressable(
                onTap: () => HapticFeedback.lightImpact(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.radiusXl),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppTokens.space3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusXl),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(a.$1,
                              color: Colors.white.withValues(alpha: 0.92),
                              size: 22),
                          const SizedBox(height: 6),
                          Text(
                            a.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Recent activity feed for the pass — last few touches at airports,
/// boarding events, scan attempts. Designed to feel like Apple
/// Wallet's transaction list under a credit card.
class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.brand});
  final AirlineBrand brand;
  @override
  Widget build(BuildContext context) {
    final entries = const [
      (Icons.qr_code_scanner_rounded, 'Boarding scanned',
          'Gate A22 · Frankfurt · 14 Mar 09:42'),
      (Icons.flight_takeoff_rounded, 'Flight pushed back',
          'FRA → JFK · 14 Mar 10:18'),
      (Icons.flight_land_rounded, 'Wheels down',
          'JFK · 14 Mar 17:54 local'),
      (Icons.update_rounded, 'Auto-updated from airline',
          'Seat reassigned 11A → 11K · 13 Mar 21:01'),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radius2xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.all(AppTokens.space4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(AppTokens.radius2xl),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.timeline_rounded,
                      color: brand.primary.withValues(alpha: 0.9),
                      size: 16),
                  const SizedBox(width: 6),
                  const Text('RECENT ACTIVITY',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2)),
                ],
              ),
              const SizedBox(height: AppTokens.space3),
              for (final e in entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: brand.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(e.$1,
                            color: Colors.white.withValues(alpha: 0.92),
                            size: 14),
                      ),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.$2,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                            Text(e.$3,
                                style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.55),
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoiseField extends StatelessWidget {
  const _NoiseField();
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 1.4,
          colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.4),
          ],
        ),
      ),
    );
  }
}
