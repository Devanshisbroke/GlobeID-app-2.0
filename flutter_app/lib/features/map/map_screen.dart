import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/app_tokens.dart';
import '../../domain/airports.dart';
import '../../widgets/glass_surface.dart';
import '../lifecycle/lifecycle_provider.dart';

/// Globe screen — 2D Skia approach (per FLUTTER_HANDOFF §11.3 option 3).
/// Uses `flutter_map` with OpenStreetMap tiles + curved-arc overlay
/// drawn via [CustomPainter]. Future iteration: switch to Impeller
/// fragment shaders for a true day/night terminator.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    strokeWidth: 2.5,
                  ),
              ],
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          left: AppTokens.space5,
          right: AppTokens.space5,
          top: MediaQuery.of(context).padding.top + AppTokens.space3,
          child: GlassSurface(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space4, vertical: AppTokens.space3),
            child: Row(
              children: [
                Icon(Icons.public_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: AppTokens.space2),
                Expanded(
                  child: Text('Globe', style: theme.textTheme.titleMedium),
                ),
                PillChip(label: '${arcs.length} routes'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Marker _marker(LatLng p, ThemeData theme) => Marker(
        point: p,
        width: 14,
        height: 14,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.45),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      );
}
