import 'package:flutter/material.dart';

import '../../app/theme/airport_typography.dart';
import '../../app/theme/app_tokens.dart';
import 'contextual_surface.dart';
import 'departure_board_flap.dart';

/// FlightCallsignBoard — a Solari-board callsign block with origin /
/// destination IATA, departure time, and gate. Used as a premium
/// header for flight detail / boarding-related surfaces.
class FlightCallsignBoard extends StatelessWidget {
  const FlightCallsignBoard({
    super.key,
    required this.callsign,
    required this.fromIata,
    required this.toIata,
    required this.depart,
    this.gate,
    this.tone,
  });

  final String callsign;
  final String fromIata;
  final String toIata;
  final String depart;
  final String? gate;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = this.tone ?? theme.colorScheme.primary;
    return ContextualSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('CALLSIGN', style: AirportFontStack.caption(context)),
              const Spacer(),
              if (gate != null && gate!.isNotEmpty) ...[
                Text('GATE',
                    style: AirportFontStack.caption(context)),
                const SizedBox(width: 6),
                DepartureBoardText(
                  text: gate!.toUpperCase(),
                  style: AirportFontStack.gate(context, size: 18),
                  tone: tone,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTokens.space2),
          DepartureBoardText(
            text: callsign.toUpperCase(),
            style: AirportFontStack.flightNumber(context, size: 22),
            tone: tone,
          ),
          const SizedBox(height: AppTokens.space3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DepartureBoardText(
                      text: fromIata.toUpperCase(),
                      style: AirportFontStack.iata(context, size: 32),
                      tone: tone,
                    ),
                    Text('FROM',
                        style: AirportFontStack.caption(context)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.flight_rounded,
                    color: tone, size: 28),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    DepartureBoardText(
                      text: toIata.toUpperCase(),
                      style: AirportFontStack.iata(context, size: 32),
                      tone: tone,
                    ),
                    Text('TO',
                        style: AirportFontStack.caption(context)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          Row(
            children: [
              Text('DEPART',
                  style: AirportFontStack.caption(context)),
              const SizedBox(width: 6),
              DepartureBoardText(
                text: depart.toUpperCase(),
                style: AirportFontStack.clock(context, size: 22),
                tone: theme.colorScheme.onSurface,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
