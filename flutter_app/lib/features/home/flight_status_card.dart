
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/pressable.dart';

/// Flight status card for the home screen.
///
/// Shows a live-feeling flight status with departure/arrival times,
/// gate information, animated progress bar, and contextual actions.
/// Appears when the user has an active trip in the BOARDING or
/// IN_FLIGHT stage.
class FlightStatusCard extends StatelessWidget {
  const FlightStatusCard({
    super.key,
    required this.flightNumber,
    required this.airline,
    required this.from,
    required this.to,
    required this.departureTime,
    required this.arrivalTime,
    required this.gate,
    required this.status,
    required this.progress,
    this.tripId,
    this.legId,
    this.onTap,
  });

  final String flightNumber;
  final String airline;
  final String from;
  final String to;
  final String departureTime;
  final String arrivalTime;
  final String gate;
  final FlightStatus status;
  final double progress; // 0.0 to 1.0
  final String? tripId;
  final String? legId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = status.color;
    final accent = theme.colorScheme.primary;

    return Pressable(
      onTap: () {
        HapticFeedback.lightImpact();
        if (tripId != null && legId != null) {
          context.push('/boarding/$tripId/$legId');
        } else {
          onTap?.call();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius2xl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withValues(alpha: isDark ? 0.22 : 0.12),
              statusColor.withValues(alpha: isDark ? 0.06 : 0.03),
            ],
          ),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.28),
            width: 0.7,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: isDark ? 0.18 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: airline + flight number + status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space3,
                    vertical: AppTokens.space1,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.32),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.55),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  flightNumber,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space4),

            // Route: FROM → TO
            Row(
              children: [
                _AirportBig(code: from),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space3,
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.flight_rounded,
                            color: accent, size: 18),
                        const SizedBox(height: 4),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusFull,
                          ),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0, 1),
                            minHeight: 3,
                            backgroundColor:
                                accent.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation(accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _AirportBig(code: to),
              ],
            ),
            const SizedBox(height: AppTokens.space3),

            // Times
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  departureTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  'Gate $gate',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                Text(
                  arrivalTime,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space3),

            // Quick actions
            Row(
              children: [
                _FlightAction(
                  icon: Icons.confirmation_number_rounded,
                  label: 'Boarding pass',
                  onTap: () {
                    if (tripId != null && legId != null) {
                      context.push('/boarding/$tripId/$legId');
                    }
                  },
                ),
                const SizedBox(width: AppTokens.space2),
                _FlightAction(
                  icon: Icons.airline_seat_individual_suite_rounded,
                  label: 'Lounge',
                  onTap: () => context.push('/lounge'),
                ),
                const SizedBox(width: AppTokens.space2),
                _FlightAction(
                  icon: Icons.map_rounded,
                  label: 'Airport',
                  onTap: () => context.push('/airport'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AirportBig extends StatelessWidget {
  const _AirportBig({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      code,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: theme.colorScheme.primary,
      ),
    );
  }
}

class _FlightAction extends StatelessWidget {
  const _FlightAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Pressable(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppTokens.space2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16,
                  color: theme.colorScheme.primary),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 9,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum FlightStatus {
  scheduled,
  boarding,
  departed,
  inFlight,
  landed,
  delayed,
  cancelled;

  String get label => switch (this) {
        scheduled => 'SCHEDULED',
        boarding => 'BOARDING',
        departed => 'DEPARTED',
        inFlight => 'IN FLIGHT',
        landed => 'LANDED',
        delayed => 'DELAYED',
        cancelled => 'CANCELLED',
      };

  Color get color => switch (this) {
        scheduled => const Color(0xFF06B6D4),
        boarding => const Color(0xFF22C55E),
        departed => const Color(0xFF0EA5E9),
        inFlight => const Color(0xFF8B5CF6),
        landed => const Color(0xFF10B981),
        delayed => const Color(0xFFF59E0B),
        cancelled => const Color(0xFFEF4444),
      };
}
