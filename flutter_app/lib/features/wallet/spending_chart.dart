import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/pressable.dart';

/// Animated spending donut chart with category breakdown.
///
/// Shows monthly spend distribution by category. Each segment
/// animates in, is tappable, and displays an inline legend.
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

  double get _total =>
      widget.categories.fold(0.0, (s, c) => s + c.amount);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _total;

    return AnimatedBuilder(
      animation: CurvedAnimation(parent: _ctrl, curve: AppTokens.easeOutSoft),
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          padding: const EdgeInsets.all(AppTokens.space4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radius2xl),
            color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              // Donut chart
              SizedBox(
                width: widget.height * 0.55,
                height: widget.height * 0.55,
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'this month',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.45),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space4),
              // Legend
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
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: widget.categories[i].color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.categories[i].label,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: _selectedIndex == i
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '\$${widget.categories[i].amount.toStringAsFixed(0)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: widget.categories[i].color,
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
    const strokeWidth = 14.0;
    var startAngle = -math.pi / 2;

    for (var i = 0; i < categories.length; i++) {
      final sweep = (categories[i].amount / total) * 2 * math.pi * progress;
      final isSelected = selectedIndex == i;
      final paint = Paint()
        ..color = categories[i].color
        ..strokeWidth = isSelected ? strokeWidth + 4 : strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (isSelected) {
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = categories[i].color.withValues(alpha: 0.08)
            ..style = PaintingStyle.fill,
        );
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep - 0.03, // small gap between segments
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

  /// Demo categories.
  static List<SpendCategory> demo() => const [
        SpendCategory(
          label: 'Transport',
          amount: 340,
          color: Color(0xFF0EA5E9),
          icon: Icons.flight_rounded,
        ),
        SpendCategory(
          label: 'Hotels',
          amount: 520,
          color: Color(0xFF8B5CF6),
          icon: Icons.hotel_rounded,
        ),
        SpendCategory(
          label: 'Food & Drink',
          amount: 180,
          color: Color(0xFF22C55E),
          icon: Icons.restaurant_rounded,
        ),
        SpendCategory(
          label: 'Shopping',
          amount: 95,
          color: Color(0xFFF59E0B),
          icon: Icons.shopping_bag_rounded,
        ),
        SpendCategory(
          label: 'Activities',
          amount: 120,
          color: Color(0xFFEC4899),
          icon: Icons.local_activity_rounded,
        ),
        SpendCategory(
          label: 'Other',
          amount: 45,
          color: Color(0xFF64748B),
        ),
      ];
}
