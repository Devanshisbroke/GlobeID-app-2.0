import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_tokens.dart';
import '../../domain/airports.dart';
import '../../widgets/animated_appearance.dart';
import '../lifecycle/lifecycle_provider.dart';

/// Map v2 — flutter_map with deeper backdrop dim, glass header pill,
/// brand-accented arcs, glow-pulsed markers.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();
  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lifecycle = ref.watch(lifecycleProvider);
    final theme = Theme.of(context);
    final markers = <Marker>[];
    final arcs = <List<LatLng>>[];

    for (final t in lifecycle.trips) {
      for (final leg in t.legs) {
        final from = getAirport(leg.from);
        final to = getAirport(leg.to);
        if (from == null || to == null) continue;
        markers.add(_marker(LatLng(from.lat, from.lng), theme));
        markers.add(_marker(LatLng(to.lat, to.lng), theme));
        arcs.add([LatLng(from.lat, from.lng), LatLng(to.lat, to.lng)]);
      }
    }

    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(20, 0),
            initialZoom: 2,
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'io.globeid.app',
            ),
            PolylineLayer(
              polylines: [
                for (final pts in arcs)
                  Polyline(
                    points: pts,
                    color: theme.colorScheme.primary,
                    strokeWidth: 3,
                  ),
              ],
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        // Vignette dim.
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.32),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: AppTokens.space5,
          right: AppTokens.space5,
          top: MediaQuery.of(context).padding.top + AppTokens.space3,
          child: AnimatedAppearance(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space4, vertical: AppTokens.space3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.public_rounded,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: AppTokens.space2),
                      Expanded(
                        child: Text('Globe',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusFull),
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.32),
                        ),
                        child: Text('${arcs.length} routes',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            )),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Marker _marker(LatLng p, ThemeData theme) => Marker(
        point: p,
        width: 18,
        height: 18,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 18 + 8 * _pulse.value,
                height: 18 + 8 * _pulse.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary
                      .withValues(alpha: (1 - _pulse.value) * 0.32),
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow:
                      AppTokens.shadowSm(tint: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      );
}
