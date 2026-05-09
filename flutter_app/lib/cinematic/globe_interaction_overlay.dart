import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/pressable.dart';

/// Overlay HUD for the cinematic globe screen.
///
/// Provides:
/// - Time-of-day scrubber (drag to change globe lighting)
/// - Layer toggle chips (clouds, aurora, terminator, traffic)
/// - Tap-on-city info card (slides up from bottom)
/// - Current coordinates HUD readout
class GlobeInteractionOverlay extends StatefulWidget {
  const GlobeInteractionOverlay({
    super.key,
    required this.onTimeChanged,
    required this.onLayerToggled,
    required this.onCityTapped,
    this.currentLat = 0,
    this.currentLng = 0,
    this.currentZoom = 1.0,
    this.selectedCity,
  });

  final ValueChanged<double> onTimeChanged;
  final void Function(String layer, bool enabled) onLayerToggled;
  final ValueChanged<String> onCityTapped;
  final double currentLat;
  final double currentLng;
  final double currentZoom;
  final GlobeCityInfo? selectedCity;

  @override
  State<GlobeInteractionOverlay> createState() =>
      _GlobeInteractionOverlayState();
}

class _GlobeInteractionOverlayState extends State<GlobeInteractionOverlay> {
  double _time = 0.5; // 0 = midnight, 1 = midnight (next day)
  final _layers = <String, bool>{
    'clouds': true,
    'aurora': true,
    'terminator': true,
    'traffic': false,
    'labels': true,
  };

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        // ── Coordinates HUD (top-left) ───────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: _CoordinateHud(
            lat: widget.currentLat,
            lng: widget.currentLng,
            zoom: widget.currentZoom,
          ),
        ),

        // ── Layer toggles (top-right) ────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final entry in _layers.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _LayerChip(
                    label: entry.key,
                    enabled: entry.value,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _layers[entry.key] = !entry.value;
                      });
                      widget.onLayerToggled(entry.key, _layers[entry.key]!);
                    },
                  ),
                ),
            ],
          ).animate().fadeIn(
                duration: AppTokens.durationMd,
                curve: AppTokens.easeOutSoft,
              ),
        ),

        // ── Time scrubber (bottom) ───────────────────────────
        Positioned(
          left: 16,
          right: 16,
          bottom: bottom + 80,
          child: _TimeScrubber(
            value: _time,
            onChanged: (v) {
              setState(() => _time = v);
              widget.onTimeChanged(v);
            },
          ),
        ),

        // ── City info card (bottom, when selected) ───────────
        if (widget.selectedCity != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: bottom + 140,
            child: _CityInfoCard(city: widget.selectedCity!)
                .animate()
                .fadeIn(duration: AppTokens.durationSm)
                .slideY(begin: 0.08, end: 0),
          ),
      ],
    );
  }
}

class _CoordinateHud extends StatelessWidget {
  const _CoordinateHud({
    required this.lat,
    required this.lng,
    required this.zoom,
  });
  final double lat;
  final double lng;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final latStr = '${lat.abs().toStringAsFixed(2)}°${lat >= 0 ? 'N' : 'S'}';
    final lngStr = '${lng.abs().toStringAsFixed(2)}°${lng >= 0 ? 'E' : 'W'}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.my_location_rounded,
              size: 12, color: Colors.white.withValues(alpha: 0.65)),
          const SizedBox(width: 6),
          Text(
            '$latStr  $lngStr  ×${zoom.toStringAsFixed(1)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.80),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  const _LayerChip({
    required this.label,
    required this.enabled,
    required this.onTap,
  });
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  IconData get _icon => switch (label) {
        'clouds' => Icons.cloud_rounded,
        'aurora' => Icons.auto_awesome_rounded,
        'terminator' => Icons.dark_mode_rounded,
        'traffic' => Icons.traffic_rounded,
        'labels' => Icons.label_rounded,
        _ => Icons.layers_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationSm,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          border: Border.all(
            color: enabled
                ? Colors.white.withValues(alpha: 0.32)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icon,
              size: 12,
              color:
                  enabled ? Colors.white : Colors.white.withValues(alpha: 0.40),
            ),
            const SizedBox(width: 5),
            Text(
              label.substring(0, 1).toUpperCase() + label.substring(1),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: enabled
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.40),
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeScrubber extends StatelessWidget {
  const _TimeScrubber({required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  String _timeLabel(double v) {
    final hours = (v * 24).floor();
    final mins = ((v * 24 - hours) * 60).floor();
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded,
              size: 14, color: Colors.white.withValues(alpha: 0.65)),
          const SizedBox(width: 8),
          Text(
            _timeLabel(value),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: Colors.white.withValues(alpha: 0.55),
                inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withValues(alpha: 0.08),
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 5,
                ),
              ),
              child: Slider(
                value: value,
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            value < 0.25 || value > 0.75
                ? Icons.nightlight_round
                : Icons.wb_sunny_rounded,
            size: 14,
            color: value < 0.25 || value > 0.75
                ? const Color(0xFF818CF8)
                : const Color(0xFFFBBF24),
          ),
        ],
      ),
    );
  }
}

class _CityInfoCard extends StatelessWidget {
  const _CityInfoCard({required this.city});
  final GlobeCityInfo city;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassSurface(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: city.tone.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            ),
            child: Center(
              child: Text(city.flag, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${city.country} · ${city.timezone}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                city.temperature,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: city.tone,
                ),
              ),
              Text(
                city.condition,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// City info model for globe tap events.
class GlobeCityInfo {
  const GlobeCityInfo({
    required this.name,
    required this.country,
    required this.flag,
    required this.timezone,
    required this.temperature,
    required this.condition,
    this.lat = 0,
    this.lng = 0,
    this.tone = const Color(0xFF0EA5E9),
  });

  final String name;
  final String country;
  final String flag;
  final String timezone;
  final String temperature;
  final String condition;
  final double lat;
  final double lng;
  final Color tone;
}
