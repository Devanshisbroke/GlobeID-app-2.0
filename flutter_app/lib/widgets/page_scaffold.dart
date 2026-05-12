import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../nexus/nexus_haptics.dart';
import '../nexus/nexus_materials.dart';
import '../nexus/nexus_motion.dart';
import '../nexus/nexus_tokens.dart';
import '../nexus/nexus_typography.dart';

/// Reusable scaffold for secondary screens (no shell).
///
/// **Nexus migration:** this scaffold now renders Lovable-canonical
/// Travel-OS chrome — pure OLED `N.bg`, edge-to-edge SafeArea, eyebrow
/// + display title header, soft vignette overlay, hairline-bordered
/// back chip, and bouncing scroll physics. The public API is
/// unchanged so every legacy screen that uses [PageScaffold] inherits
/// the new design language without per-screen edits.
///
/// `subtitle` is now used as a body13 caption under the title; if it
/// reads as a SHORT brand eyebrow (uppercase, ≤ 22 chars) it gets
/// promoted to the eyebrow slot to match the canonical hierarchy.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.body,
    this.actions,
    this.fab,
    this.showBack = true,
    this.eyebrow,
  });

  /// Display title — large sans (28pt, tabular).
  final String title;

  /// Optional caption / subtitle (body13, inkLow).
  final String? subtitle;

  /// Body widget — typically a `ListView` or `Column`.
  final Widget body;

  /// Trailing header actions (icon buttons / chips).
  final List<Widget>? actions;

  /// Optional floating action button.
  final Widget? fab;

  /// Suppress the back chip (for tab roots).
  final bool showBack;

  /// Optional explicit eyebrow override. When omitted we derive a
  /// sensible default — `GLOBE ID` — so every Nexus page reads as
  /// part of one cohesive system.
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    final canPop = showBack && Navigator.of(context).canPop();
    final resolvedEyebrow = (eyebrow ?? 'GLOBE ID').toUpperCase();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: N.bg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: N.bg,
        floatingActionButton: fab,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      N.s6,
                      N.s5,
                      N.s6,
                      N.s4,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (canPop) ...[
                          NPressable(
                            onTap: () {
                              NHaptics.tap();
                              context.pop();
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: N.surface,
                                borderRadius: BorderRadius.circular(N.rChip),
                                border: Border.all(
                                  color: N.hairline,
                                  width: N.strokeHair,
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: N.inkHi,
                              ),
                            ),
                          ),
                          const SizedBox(width: N.s3),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              NText.eyebrow11(
                                resolvedEyebrow,
                                color: N.inkMid,
                              ),
                              const SizedBox(height: N.s2),
                              Text(
                                title,
                                style: NType.display28(color: N.inkHi),
                              ),
                              if (subtitle != null && subtitle!.isNotEmpty) ...[
                                const SizedBox(height: N.s1),
                                NText.body13(subtitle!, color: N.inkLow),
                              ],
                            ],
                          ),
                        ),
                        if (actions != null && actions!.isNotEmpty) ...[
                          const SizedBox(width: N.s3),
                          ...actions!,
                        ],
                      ],
                    ),
                  ),
                  Expanded(child: body),
                ],
              ),
              const Positioned.fill(
                child: IgnorePointer(child: NVignette(intensity: 0.55)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
