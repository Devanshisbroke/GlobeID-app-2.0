import 'package:flutter/material.dart';

import '../nexus_materials.dart';
import '../nexus_tokens.dart';
import '../nexus_typography.dart';

/// Top status bar — the "11:08 · Biometric · Verified" / "Wallet · Online"
/// header that sits flush with the device status bar. Edge-to-edge.
class NStatusBar extends StatelessWidget {
  const NStatusBar({
    super.key,
    required this.time,
    required this.right,
    this.rightDotTone = N.success,
  });

  final String time;
  final String right;
  final Color rightDotTone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(N.s6, N.s5, N.s6, N.s3),
      child: Row(
        children: [
          Text(time, style: NType.title16(color: N.ink)),
          const Spacer(),
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: N.s2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rightDotTone,
            ),
          ),
          NText.eyebrow11(right, color: N.inkMid),
        ],
      ),
    );
  }
}

/// Section header — small caps brand line + big sans title.
///
///   GLOBE ID · TRAVEL OS
///   Global Reserve
class NSectionHeader extends StatelessWidget {
  const NSectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NText.eyebrow11(eyebrow, color: N.inkMid),
              const SizedBox(height: N.s2),
              Text(title, style: NType.title22(color: N.inkHi)),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Page scaffold for every Nexus screen. Provides:
///   • Pure OLED background
///   • Top status bar
///   • Scrolling content area
///   • Optional pinned top banner
///   • Optional pinned bottom auth sheet
///   • Optional bottom nav (provided by caller)
class NScaffold extends StatelessWidget {
  const NScaffold({
    super.key,
    required this.time,
    required this.right,
    required this.children,
    this.rightDotTone = N.success,
    this.topBanner,
    this.bottomAuth,
    this.bottomNav,
    this.padding = N.pagePad,
  });

  final String time;
  final String right;
  final Color rightDotTone;
  final List<Widget> children;
  final Widget? topBanner;
  final Widget? bottomAuth;
  final Widget? bottomNav;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: N.bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                NStatusBar(
                  time: time,
                  right: right,
                  rightDotTone: rightDotTone,
                ),
                if (topBanner != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      N.s6,
                      0,
                      N.s6,
                      N.s3,
                    ),
                    child: topBanner!,
                  ),
                ],
                Expanded(
                  child: ListView(
                    padding: padding,
                    physics: const BouncingScrollPhysics(),
                    children: children,
                  ),
                ),
                if (bottomAuth != null) bottomAuth!,
                if (bottomNav != null) bottomNav!,
              ],
            ),
            const Positioned.fill(
              child: IgnorePointer(child: NVignette(intensity: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
