import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Animated travel stats header with counters that animate from 0.
///
/// Shows: countries visited · flights · distance · hours in air.
/// Each counter rolls up on first appearance.
class TravelStatsHeader extends StatefulWidget {
  const TravelStatsHeader({
    super.key,
    required this.countries,
    required this.flights,
    required this.distanceKm,
    required this.hoursInAir,
  });

  final int countries;
  final int flights;
  final int distanceKm;
  final int hoursInAir;

  @override
  State<TravelStatsHeader> createState() => _TravelStatsHeaderState();
}

class _TravelStatsHeaderState extends State<TravelStatsHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: CurvedAnimation(parent: _ctrl, curve: AppTokens.easeOutSoft),
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space4,
            vertical: AppTokens.space3,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusXl),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.08),
                theme.colorScheme.primary.withValues(alpha: 0.02),
              ],
            ),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(
                value: (widget.countries * t).round(),
                label: 'countries',
                icon: Icons.public_rounded,
              ),
              _divider(theme),
              _Stat(
                value: (widget.flights * t).round(),
                label: 'flights',
                icon: Icons.flight_rounded,
              ),
              _divider(theme),
              _Stat(
                value: (widget.distanceKm * t).round(),
                label: 'km',
                icon: Icons.route_rounded,
                compact: true,
              ),
              _divider(theme),
              _Stat(
                value: (widget.hoursInAir * t).round(),
                label: 'hrs',
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _divider(ThemeData theme) => Container(
        width: 1,
        height: 28,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.icon,
    this.compact = false,
  });

  final int value;
  final String label;
  final IconData icon;
  final bool compact;

  String _format(int v) {
    if (v >= 1000) {
      return '${(v / 1000).toStringAsFixed(v >= 10000 ? 0 : 1)}k';
    }
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 14, color: theme.colorScheme.primary.withValues(alpha: 0.65)),
        const SizedBox(height: 4),
        Text(
          _format(value),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
            fontWeight: FontWeight.w600,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
