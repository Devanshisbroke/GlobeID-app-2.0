import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../nexus/nexus_tokens.dart';
import '../../widgets/pressable.dart';

/// Spending donut chart — **Nexus-aligned restrained breakdown.**
///
/// Was a saturated cyan / purple / green / amber / pink donut with
/// bright-on-tinted legend labels. After the Travel-OS / Wallet
/// migration the chart speaks the same restrained palette as the
/// rest of the surface: flat hairline panel, ink ladder, champagne
/// accent for the active segment, signal tones reserved for
/// success / critical.
///
/// Each segment animates in, is tappable, and reveals an inline
/// legend with tabular-figure dollar amounts.
class SpendingChart extends StatefulWidget {
  const SpendingChart({
    super.key,
    required this.categories,
    this.height = 200,
  });

  final List<SpendCategory> categories;
  final double height;

  @override
  State<SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<SpendingChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _total => widget.categories.fold(0.0, (s, c) => s + c.amount);

  @override
  Widget build(BuildContext context) {
    final total = _total;

    return AnimatedBuilder(
      animation: CurvedAnimation(parent: _ctrl, curve: AppTokens.easeOutSoft),
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          padding: const EdgeInsets.all(AppTokens.space4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(N.rCard),
            color: N.surface,
            border: Border.all(
              color: N.hairline,
              width: N.strokeHair,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: widget.height * 0.55,
                height: widget.height * 0.55,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _DonutPainter(
                      categories: widget.categories,
                      total: total,
                      progress: t,
                      selectedIndex: _selectedIndex,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '\$${total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: N.inkHi,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'THIS MONTH',
                            style: TextStyle(
                              color: N.inkLow,
                              fontSize: 9,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < widget.categories.length; i++)
                      Pressable(
                        onTap: () => setState(() {
                          _selectedIndex = _selectedIndex == i ? null : i;
                        }),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: widget.categories[i].color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.categories[i].label,
                                  style: TextStyle(
                                    color: _selectedIndex == i
                                        ? N.inkHi
                                        : N.inkMid,
                                    fontSize: 12,
                                    fontWeight: _selectedIndex == i
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '\$${widget.categories[i].amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: _selectedIndex == i
                                      ? N.inkHi
                                      : N.inkMid,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.categories,
    required this.total,
    required this.progress,
    this.selectedIndex,
  });

  final List<SpendCategory> categories;
  final double total;
  final double progress;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    const strokeWidth = 10.0;
    var startAngle = -math.pi / 2;

    // Hairline track behind the segments.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = N.hairline
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke,
    );

    for (var i = 0; i < categories.length; i++) {
      final sweep = (categories[i].amount / total) * 2 * math.pi * progress;
      final isSelected = selectedIndex == i;
      final paint = Paint()
        ..color = isSelected
            ? categories[i].color
            : categories[i].color.withValues(alpha: 0.80)
        ..strokeWidth = isSelected ? strokeWidth + 3 : strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep - 0.025,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.progress != progress || old.selectedIndex != selectedIndex;
}

class SpendCategory {
  const SpendCategory({
    required this.label,
    required this.amount,
    required this.color,
    this.icon,
  });

  final String label;
  final double amount;
  final Color color;
  final IconData? icon;

  /// Demo categories — using the restrained Nexus categorical palette
  /// (ink ladder + steel + champagne + signal tokens) instead of the
  /// previous saturated rainbow.
  static List<SpendCategory> demo() => const [
        SpendCategory(
          label: 'Transport',
          amount: 340,
          color: N.steel,
          icon: Icons.flight_rounded,
        ),
        SpendCategory(
          label: 'Hotels',
          amount: 520,
          color: N.tierGold,
          icon: Icons.hotel_rounded,
        ),
        SpendCategory(
          label: 'Food & Drink',
          amount: 180,
          color: N.success,
          icon: Icons.restaurant_rounded,
        ),
        SpendCategory(
          label: 'Shopping',
          amount: 95,
          color: N.warning,
          icon: Icons.shopping_bag_rounded,
        ),
        SpendCategory(
          label: 'Activities',
          amount: 120,
          color: N.info,
          icon: Icons.local_activity_rounded,
        ),
        SpendCategory(
          label: 'Other',
          amount: 45,
          color: N.inkFaint,
        ),
      ];
}
