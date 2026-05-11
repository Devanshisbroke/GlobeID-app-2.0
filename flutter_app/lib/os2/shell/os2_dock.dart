import 'dart:ui';

import 'package:flutter/material.dart';

import '../os2_tokens.dart';
import '../primitives/os2_magnetic.dart';

/// OS 2.0 — Floating spatial dock.
///
/// Replaces the legacy 6-tab BottomNavigationBar entirely. Renders as
/// a floating squircle slab that hovers above the world floor, with:
///   • a backdrop blur (the only blur in OS 2.0 — restricted to chrome);
///   • a tone-tinted active pill that magnetically morphs between
///     positions on world change;
///   • per-slot icon + label with the active world's icon raised in ink;
///   • a hairline rim tinted by the active world.
///
/// Six slots: Pulse / Identity / Wallet / Travel / Discover / Services.
class Os2Dock extends StatelessWidget {
  const Os2Dock({
    super.key,
    required this.active,
    required this.onSelect,
  });

  final Os2World active;
  final ValueChanged<Os2World> onSelect;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final tone = active.tone;
    const worlds = Os2World.values;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Os2.space4,
        0,
        Os2.space4,
        pad.bottom + Os2.space2,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Os2.rFloor),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: Os2.floor1.withValues(alpha: 0.78),
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(Os2.rFloor),
                side: BorderSide(
                  color: tone.withValues(alpha: 0.22),
                  width: Os2.strokeFine,
                ),
              ),
              shadows: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 32,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: tone.withValues(alpha: 0.10),
                  blurRadius: 24,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: SizedBox(
              height: 60,
              child: LayoutBuilder(
                builder: (context, box) {
                  final slotWidth = box.maxWidth / worlds.length;
                  final activeIndex = worlds.indexOf(active);
                  return Stack(
                    children: [
                      // Magnetic pill.
                      AnimatedPositioned(
                        duration: Os2.mCruise,
                        curve: Os2.cTakeoff,
                        left: slotWidth * activeIndex + 6,
                        top: 8,
                        bottom: 8,
                        width: slotWidth - 12,
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: tone.withValues(alpha: 0.16),
                            shape: ContinuousRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                              side: BorderSide(
                                color: tone.withValues(alpha: 0.32),
                                width: Os2.strokeFine,
                              ),
                            ),
                            shadows: [
                              BoxShadow(
                                color: tone.withValues(alpha: 0.18),
                                blurRadius: 14,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Slots.
                      Row(
                        children: [
                          for (final w in worlds)
                            Expanded(
                              child: Os2Magnetic(
                                onTap: () => onSelect(w),
                                pressedScale: 0.92,
                                child: _DockSlot(
                                  world: w,
                                  active: w == active,
                                  tone: tone,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockSlot extends StatelessWidget {
  const _DockSlot({
    required this.world,
    required this.active,
    required this.tone,
  });

  final Os2World world;
  final bool active;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final ink = active ? Os2.inkBright : Os2.inkMid;
    return SizedBox(
      height: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(world.icon, size: 19, color: active ? tone : ink),
          const SizedBox(height: 2),
          Text(
            world.label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: active ? Os2.inkBright : Os2.inkLow,
            ),
          ),
        ],
      ),
    );
  }
}
