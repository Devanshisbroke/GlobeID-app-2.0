import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import 'contextual_surface.dart';

/// Premium info-strip rail — a horizontal scroll of compact info
/// strips, each with an icon, label, value, and optional accent
/// gradient. Used as a quick-hit context bar above hero content
/// (e.g. profile, identity, security, lifecycle hub).
class PremiumInfoRail extends StatelessWidget {
  const PremiumInfoRail({
    super.key,
    required this.tiles,
    this.height = 84,
  });

  final List<InfoRailTile> tiles;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space2),
        itemCount: tiles.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTokens.space2),
        itemBuilder: (ctx, i) => _Tile(tile: tiles[i]),
      ),
    );
  }
}

@immutable
class InfoRailTile {
  const InfoRailTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color tone;
  final VoidCallback? onTap;
}

class _Tile extends StatelessWidget {
  const _Tile({required this.tile});
  final InfoRailTile tile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: tile.onTap,
      child: SizedBox(
        width: 158,
        child: ContextualSurface(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space3,
            AppTokens.space2,
            AppTokens.space3,
            AppTokens.space2,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tile.tone.withValues(alpha: 0.55),
                      tile.tone.withValues(alpha: 0.18),
                    ],
                  ),
                  border: Border.all(
                    color: tile.tone.withValues(alpha: 0.5),
                    width: 0.7,
                  ),
                ),
                child: Icon(tile.icon, size: 16, color: Colors.white),
              ),
              const SizedBox(width: AppTokens.space2),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tile.label.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontSize: 9.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      tile.value,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
