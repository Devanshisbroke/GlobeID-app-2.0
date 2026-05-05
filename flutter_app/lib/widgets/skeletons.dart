import 'package:flutter/material.dart';

import '../app/theme/app_tokens.dart';

/// Premium shimmer rectangle. Sweeps a soft highlight gradient across
/// the surface on a 1.5s loop. Used across hydration screens.
class SkeletonBlock extends StatefulWidget {
  const SkeletonBlock({
    super.key,
    this.height = 18,
    this.width,
    this.radius = 8,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
    ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);
    final highlight = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.55);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value; // 0..1
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: Container(
            width: widget.width,
            height: widget.height,
            color: base,
            child: FractionallySizedBox(
              widthFactor: 1.5,
              child: Transform.translate(
                offset: Offset((t * 2 - 1.0) * (widget.width ?? 200) * 1.4, 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: const [0, 0.5, 1],
                      colors: [
                        base.withValues(alpha: 0),
                        highlight,
                        base.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.count = 4,
    this.itemHeight = 84,
  });

  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppTokens.space5),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.space3),
      itemBuilder: (_, __) =>
          SkeletonBlock(height: itemHeight, radius: AppTokens.radiusLg),
    );
  }
}
