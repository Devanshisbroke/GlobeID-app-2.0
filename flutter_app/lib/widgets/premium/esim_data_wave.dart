import 'package:flutter/material.dart';

import '../../app/theme/airport_typography.dart';
import '../../app/theme/app_tokens.dart';
import 'contextual_surface.dart';
import 'departure_board_flap.dart';
import 'liquid_wave_surface.dart';

/// EsimDataWave — a poured-fluid bar showing data plan size, with
/// departure-board callsign for the destination country. Used as a
/// premium hero block on the eSIM screen.
class EsimDataWave extends StatelessWidget {
  const EsimDataWave({
    super.key,
    required this.dataLabel,
    required this.country,
    required this.tone,
    this.duration = '7 days',
    this.priceLabel,
    this.percent = 1.0,
  });

  final String dataLabel;
  final String country;
  final Color tone;
  final String duration;
  final String? priceLabel;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ContextualSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('eSIM · $duration',
                  style: AirportFontStack.caption(context)),
              const Spacer(),
              if (priceLabel != null)
                Text(priceLabel!,
                    style: AirportFontStack.flightNumber(context, size: 14)
                        .copyWith(color: tone)),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          DepartureBoardText(
            text: country.toUpperCase(),
            style: AirportFontStack.iata(context, size: 28),
            tone: tone,
          ),
          const SizedBox(height: AppTokens.space2),
          Text(dataLabel,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              )),
          const SizedBox(height: AppTokens.space3),
          LiquidWaveSurface(
            progress: percent.clamp(0.05, 1.0),
            tone: tone,
            height: 48,
          ),
        ],
      ),
    );
  }
}
