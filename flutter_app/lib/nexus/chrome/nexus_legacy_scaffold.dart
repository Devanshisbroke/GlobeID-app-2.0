import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../nexus_haptics.dart';
import '../nexus_materials.dart';
import '../nexus_motion.dart';
import '../nexus_tokens.dart';
import '../nexus_typography.dart';

/// One-line scaffold migration for legacy feature screens.
///
/// Wraps any legacy screen body with the canonical Nexus chrome:
///
///   • Pure-OLED `N.bg` substrate (no Material gradient lift)
///   • Vignette overlay
///   • Edge-to-edge SafeArea, bouncing scroll physics
///   • Eyebrow + display title header (Lovable Travel OS pattern)
///   • Optional back affordance with haptic
///   • Optional trailing icon button
///   • Optional pinned-top banner (e.g. update / error)
///   • Optional pinned-bottom action sheet
///
/// Use this in place of `Scaffold(appBar: AppBar(title: …), body: …)` for
/// any legacy screen. The header below the status bar acts as the
/// AppBar replacement and stays inside the scroll, matching the
/// canonical Travel OS / Wallet refs.
///
/// Example:
///
/// ```dart
/// return NexusLegacyScaffold(
///   eyebrow: 'GLOBE ID · IDENTITY',
///   title: 'Audit log',
///   subtitle: 'Last 30 days · tamper-evident',
///   children: [
///     NPanel(child: …),
///     const SizedBox(height: N.s4),
///     NPanel(child: …),
///   ],
/// );
/// ```
class NexusLegacyScaffold extends StatelessWidget {
  const NexusLegacyScaffold({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.children = const [],
    this.body,
    this.onBack,
    this.trailing,
    this.topBanner,
    this.bottomAuth,
    this.bottomNav,
    this.padding = N.pagePad,
    this.hideBack = false,
    this.scrollController,
    this.bottom,
    this.floatingActionButton,
  });

  /// Brand eyebrow line — small caps. e.g. `GLOBE ID · WALLET`.
  final String eyebrow;

  /// Display title — large sans. e.g. `Send`, `Vault`, `Audit log`.
  final String title;

  /// Optional subtitle — body 13. e.g. `Last 30 days · tamper-evident`.
  final String? subtitle;

  /// Scrollable content as a list of slivers-style widgets.
  /// Most callers should use this.
  final List<Widget> children;

  /// Alternative for callers that need a single custom body (e.g. a
  /// CustomScrollView). When provided, [children] is ignored.
  final Widget? body;

  /// Override back-button behaviour. Defaults to `Navigator.pop` with
  /// a `NHaptics.tap` tick.
  final VoidCallback? onBack;

  /// Optional trailing icon (e.g. search / filter / settings).
  final Widget? trailing;

  /// Optional pinned-top attention strip — fills under the header.
  final Widget? topBanner;

  /// Optional pinned-bottom auth / commit sheet.
  final Widget? bottomAuth;

  /// Optional pinned-bottom nav (e.g. the OS2 dock).
  final Widget? bottomNav;

  /// Horizontal page padding override. Defaults to `N.pagePad`.
  final EdgeInsets padding;

  /// When true, suppresses the back chevron (use for tab roots).
  final bool hideBack;

  /// Optional ScrollController for the inner ListView. Ignored when
  /// [body] is supplied.
  final ScrollController? scrollController;

  /// Sticky-bottom widget below the scroll (sits above bottomAuth).
  final Widget? bottom;

  /// Optional FAB (uses Material's positioning).
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final canPop = !hideBack && Navigator.of(context).canPop();
    final header = _LegacyHeader(
      eyebrow: eyebrow,
      title: title,
      subtitle: subtitle,
      canPop: canPop,
      onBack: onBack ??
          () {
            NHaptics.tap();
            Navigator.of(context).maybePop();
          },
      trailing: trailing,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: N.bg,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: N.bg,
        floatingActionButton: floatingActionButton,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  header,
                  if (topBanner != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        N.s6,
                        0,
                        N.s6,
                        N.s3,
                      ),
                      child: topBanner!,
                    ),
                  Expanded(
                    child: body ??
                        ListView(
                          controller: scrollController,
                          padding: padding,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          children: [
                            ...children,
                            const SizedBox(height: N.s12),
                          ],
                        ),
                  ),
                  if (bottom != null) bottom!,
                  if (bottomAuth != null) bottomAuth!,
                  if (bottomNav != null) bottomNav!,
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

class _LegacyHeader extends StatelessWidget {
  const _LegacyHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.canPop,
    required this.onBack,
    required this.trailing,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final bool canPop;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(N.s6, N.s5, N.s6, N.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canPop) ...[
            NPressable(
              onTap: onBack,
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
                NText.eyebrow11(eyebrow, color: N.inkMid),
                const SizedBox(height: N.s2),
                Text(title, style: NType.display28(color: N.inkHi)),
                if (subtitle != null) ...[
                  const SizedBox(height: N.s1),
                  NText.body13(subtitle!, color: N.inkLow),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: N.s3),
            trailing!,
          ],
        ],
      ),
    );
  }
}
