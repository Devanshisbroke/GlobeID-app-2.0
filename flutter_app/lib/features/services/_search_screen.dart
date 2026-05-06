import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';

/// Shared list scaffold for service sub-screens (hotels / rides / food /
/// activities / transport). Each sub-screen passes a fetcher that returns
/// a List of `{title, subtitle, price?, rating?}` maps.
class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.fetcher,
    this.tone,
    this.heroLabel,
  });

  final String title;
  final IconData icon;
  final Color? tone;
  final Future<List<Map<String, dynamic>>> Function() fetcher;
  final String? heroLabel;

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  late Future<List<Map<String, dynamic>>> _future = widget.fetcher();
  final Set<int> _saved = <int>{};
  int? _confirmedIndex;

  Future<void> _refresh() async {
    HapticFeedback.lightImpact();
    setState(() {
      _future = widget.fetcher();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = widget.tone ?? theme.colorScheme.primary;
    return PageScaffold(
      title: widget.title,
      subtitle: widget.heroLabel ?? 'Curated around your current itinerary',
      actions: [
        _CircleAction(
          icon: Icons.tune_rounded,
          tone: tone,
          onTap: () => HapticFeedback.selectionClick(),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(tone),
                      ),
                    ),
                  ),
                ],
              );
            }
            if (snap.hasError) {
              return EmptyState(
                title: '${widget.title} unavailable',
                message: snap.error.toString(),
                icon: Icons.cloud_off_rounded,
              );
            }
            final items = snap.data ?? const [];
            if (items.isEmpty) {
              return EmptyState(
                title: 'Nothing nearby',
                message:
                    'Tell us where you\'re heading and we\'ll find ${widget.title.toLowerCase()}.',
                icon: widget.icon,
              );
            }
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                AnimatedAppearance(
                  child: _HeroPanel(
                    title: widget.title,
                    label: widget.heroLabel,
                    icon: widget.icon,
                    tone: tone,
                    count: items.length,
                    top: items.first,
                  ),
                ),
                const SizedBox(height: AppTokens.space3),
                AnimatedAppearance(
                  delay: const Duration(milliseconds: 80),
                  child: _ItineraryStrip(tone: tone),
                ),
                const SizedBox(height: AppTokens.space3),
                for (var i = 0; i < items.length; i++)
                  AnimatedAppearance(
                    delay: Duration(milliseconds: 60 * i),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: AppTokens.space3),
                      child: _ServiceRow(
                        index: i,
                        data: items[i],
                        icon: widget.icon,
                        tone: tone,
                        saved: _saved.contains(i),
                        confirmed: _confirmedIndex == i,
                        onSave: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _saved.contains(i)
                                ? _saved.remove(i)
                                : _saved.add(i);
                          });
                        },
                        onConfirm: () {
                          HapticFeedback.mediumImpact();
                          setState(() => _confirmedIndex = i);
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.title,
    required this.icon,
    required this.tone,
    required this.count,
    required this.top,
    this.label,
  });

  final String title;
  final String? label;
  final IconData icon;
  final Color tone;
  final int count;
  final Map<String, dynamic> top;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topTitle = top['title']?.toString() ?? title;
    return PremiumCard(
      padding: EdgeInsets.zero,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          tone.withValues(alpha: 0.92),
          Color.lerp(tone, Colors.black, 0.42)!,
        ],
      ),
      child: SizedBox(
        height: 210,
        child: Stack(
          children: [
            Positioned.fill(
                child: CustomPaint(painter: _ServiceHeroPainter(tone))),
            Positioned(
              right: -20,
              top: -18,
              child: Transform.rotate(
                angle: -0.18,
                child: Icon(
                  icon,
                  size: 180,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTokens.space5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _GlassBadge(icon: icon, label: '$count live options'),
                      const Spacer(),
                      _GlassBadge(
                        icon: Icons.auto_awesome_rounded,
                        label: 'Smart ranked',
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    label ?? 'Best match for your itinerary',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space2),
                  Text(
                    topTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space2),
                  Text(
                    top['subtitle']?.toString() ??
                        'Verified availability, identity-ready checkout.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.76),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceHeroPainter extends CustomPainter {
  const _ServiceHeroPainter(this.tone);
  final Color tone;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.12);
    for (var i = 0; i < 7; i++) {
      final y = size.height * (0.15 + i * 0.13);
      final path = Path()..moveTo(-20, y);
      path.quadraticBezierTo(
        size.width * 0.38,
        y - 34 * math.sin(i + 1),
        size.width + 20,
        y + 22 * math.cos(i + 2),
      );
      canvas.drawPath(path, paint);
    }
    canvas.drawCircle(
      Offset(size.width * 0.22, size.height * 0.20),
      70,
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
    canvas.drawCircle(
      Offset(size.width * 0.86, size.height * 0.88),
      120,
      Paint()..color = tone.withValues(alpha: 0.24),
    );
  }

  @override
  bool shouldRepaint(covariant _ServiceHeroPainter oldDelegate) =>
      oldDelegate.tone != tone;
}

class _GlassBadge extends StatelessWidget {
  const _GlassBadge({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItineraryStrip extends StatelessWidget {
  const _ItineraryStrip({required this.tone});
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard.flat(
      padding: const EdgeInsets.all(AppTokens.space3),
      child: Row(
        children: [
          _TimelineDot(tone: tone, icon: Icons.flight_land_rounded),
          Expanded(
            child: Container(
              height: 1,
              color: tone.withValues(alpha: 0.24),
            ),
          ),
          _TimelineDot(tone: tone, icon: Icons.hotel_rounded),
          Expanded(
            child: Container(
              height: 1,
              color: tone.withValues(alpha: 0.24),
            ),
          ),
          _TimelineDot(tone: tone, icon: Icons.verified_rounded),
          const SizedBox(width: AppTokens.space3),
          Text(
            'Identity-ready checkout',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({required this.tone, required this.icon});
  final Color tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tone.withValues(alpha: 0.14),
        border: Border.all(color: tone.withValues(alpha: 0.32)),
      ),
      child: Icon(icon, size: 17, color: tone),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.index,
    required this.data,
    required this.icon,
    required this.tone,
    required this.saved,
    required this.confirmed,
    required this.onSave,
    required this.onConfirm,
  });
  final int index;
  final Map<String, dynamic> data;
  final IconData icon;
  final Color tone;
  final bool saved;
  final bool confirmed;
  final VoidCallback onSave;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = (data['rating'] as num?)?.toDouble();
    final title = data['title']?.toString() ?? '';
    final price = data['price'];
    final currency = data['currency']?.toString() ?? 'USD';
    return Pressable(
      scale: 0.98,
      onTap: onConfirm,
      child: PremiumCard(
        padding: EdgeInsets.zero,
        borderColor: confirmed
            ? tone.withValues(alpha: 0.70)
            : tone.withValues(alpha: 0.18),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 92,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        tone.withValues(alpha: 0.34),
                        tone.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CardPatternPainter(tone: tone, seed: index),
                  ),
                ),
                Positioned(
                  left: AppTokens.space4,
                  bottom: AppTokens.space4,
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusLg),
                          color: Colors.white.withValues(alpha: 0.16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Icon(icon, color: Colors.white, size: 23),
                      ),
                      const SizedBox(width: AppTokens.space3),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width - 172,
                        ),
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: AppTokens.space3,
                  top: AppTokens.space3,
                  child: _CircleAction(
                    icon: saved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    tone: saved ? const Color(0xFFE11D48) : Colors.white,
                    onTap: onSave,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: Column(
                children: [
                  if (data['subtitle'] != null) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(data['subtitle'].toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.66),
                          )),
                    ),
                    const SizedBox(height: AppTokens.space3),
                  ],
                  Row(
                    children: [
                      if (rating != null)
                        _MetricChip(
                          icon: Icons.star_rounded,
                          label: rating.toStringAsFixed(1),
                          tone: const Color(0xFFF59E0B),
                        ),
                      if (rating != null) const SizedBox(width: 8),
                      _MetricChip(
                        icon: Icons.verified_user_rounded,
                        label: 'Verified',
                        tone: tone,
                      ),
                      const Spacer(),
                      if (price != null)
                        Text(
                          _priceText(currency, price),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: tone,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space3),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onConfirm,
                      icon: Icon(
                        confirmed
                            ? Icons.check_circle_rounded
                            : Icons.bolt_rounded,
                        size: 18,
                      ),
                      label: Text(
                        confirmed ? 'Added to trip' : _ctaFor(title),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: confirmed
                            ? const Color(0xFF059669)
                            : tone.withValues(alpha: 0.95),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusLg),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                  if (confirmed) ...[
                    const SizedBox(height: AppTokens.space2),
                    Text('Synced to itinerary timeline · receipt vault ready',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF059669),
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _priceText(String currency, Object price) {
    final symbol = switch (currency) {
      'EUR' => '€',
      'GBP' => '£',
      'JPY' => '¥',
      _ => r'$',
    };
    return '$symbol$price';
  }

  String _ctaFor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('uber') ||
        lower.contains('lyft') ||
        lower.contains('bolt') ||
        lower.contains('pickup')) {
      return 'Request now';
    }
    if (lower.contains('hotel') ||
        lower.contains('aman') ||
        lower.contains('andaz') ||
        lower.contains('conrad')) {
      return 'Reserve stay';
    }
    return 'Add to trip';
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.tone,
    required this.onTap,
  });

  final IconData icon;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Icon(icon, size: 18, color: tone),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.tone,
  });

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        color: tone.withValues(alpha: 0.12),
        border: Border.all(color: tone.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tone),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: tone,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardPatternPainter extends CustomPainter {
  const _CardPatternPainter({required this.tone, required this.seed});
  final Color tone;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.12);
    for (var i = 0; i < 5; i++) {
      final y = (i + 1) * size.height / 6;
      final path = Path()..moveTo(0, y);
      path.quadraticBezierTo(
        size.width * 0.45,
        y + math.sin(i + seed) * 24,
        size.width,
        y - math.cos(seed + i) * 18,
      );
      canvas.drawPath(path, paint);
    }
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.28),
      46,
      Paint()..color = tone.withValues(alpha: 0.18),
    );
  }

  @override
  bool shouldRepaint(covariant _CardPatternPainter oldDelegate) =>
      oldDelegate.tone != tone || oldDelegate.seed != seed;
}
