import 'package:flutter/material.dart';

import '../bible_tokens.dart';
import '../bible_typography.dart';
import '../materials/bible_atmosphere.dart';
import 'bible_pressable.dart';

/// GlobeID — **PageScaffold** (§10).
///
/// The canonical screen frame. Wraps every Bible screen and provides:
///   * `BibleAtmosphere` substrate driven by `emotion`.
///   * Edge-to-edge fullscreen rendering.
///   * Optional title row with back-affordance + trailing chip.
///   * SafeArea-aware body.
///
/// Density is driven by the screen's emotional register, not by data
/// volume. Hero screens (lock, arrival, onboarding) pass
/// `BDensity.atrium`; data-dense screens (treasury, FX, kiosk) pass
/// `BDensity.cabin`.
class BiblePageScaffold extends StatelessWidget {
  const BiblePageScaffold({
    super.key,
    required this.child,
    this.emotion = BEmotion.stillness,
    this.tone,
    this.density = BDensity.concourse,
    this.title,
    this.eyebrow,
    this.leading,
    this.trailing,
    this.bottomBar,
    this.floatingChrome,
    this.applySafePadding = true,
    this.scroll = true,
    this.quality = BRenderQuality.normal,
  });

  final Widget child;
  final BEmotion emotion;
  final Color? tone;
  final BDensity density;

  /// Optional page title rendered as Atlas-display.
  final String? title;

  /// Optional uppercase eyebrow above the title.
  final String? eyebrow;

  /// Custom leading widget (defaults to back chevron when route can pop).
  final Widget? leading;

  /// Custom trailing widget on the title row.
  final Widget? trailing;

  /// Bottom-pinned chrome (e.g. cinematic CTA).
  final Widget? bottomBar;

  /// Floating chrome overlay (HUD, voice orb, command palette trigger).
  final Widget? floatingChrome;

  final bool applySafePadding;
  final bool scroll;
  final BRenderQuality quality;

  @override
  Widget build(BuildContext context) {
    final body = _body(context);
    final positioned = floatingChrome == null
        ? body
        : Stack(
            fit: StackFit.expand,
            children: [
              body,
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(child: floatingChrome!),
              ),
            ],
          );
    return BibleAtmosphere(
      emotion: emotion,
      tone: tone,
      quality: quality,
      child: positioned,
    );
  }

  Widget _body(BuildContext context) {
    final headerVisible = title != null || eyebrow != null || leading != null;
    final padding = density.pagePadding;
    final canPop = leading != null
        ? true
        : (ModalRoute.of(context)?.canPop ?? false);

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (headerVisible)
          Padding(
            padding: EdgeInsets.fromLTRB(
              padding.left,
              padding.top + B.space2,
              padding.right,
              B.space4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (canPop || leading != null)
                  Padding(
                    padding: const EdgeInsets.only(right: B.space3),
                    child: leading ??
                        BiblePressable(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.06),
                              border: Border.all(
                                color: B.hairlineLight,
                                width: 0.6,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 14,
                              color: B.inkOnDarkHigh,
                            ),
                          ),
                        ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eyebrow != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: B.space1),
                          child: BText.eyebrow(eyebrow!, color: tone ?? B.inkOnDarkLow),
                        ),
                      if (title != null)
                        BText.display(
                          title!,
                          size: 24,
                          color: B.inkOnDarkHigh,
                          maxLines: 1,
                        ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        if (scroll)
          Expanded(
            child: ScrollConfiguration(
              behavior: const _BibleScrollBehavior(),
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  padding.left,
                  headerVisible ? 0 : padding.top,
                  padding.right,
                  padding.bottom + (bottomBar != null ? 96 : 24),
                ),
                children: [child],
              ),
            ),
          )
        else
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                padding.left,
                headerVisible ? 0 : padding.top,
                padding.right,
                padding.bottom + (bottomBar != null ? 96 : 24),
              ),
              child: child,
            ),
          ),
      ],
    );

    if (applySafePadding) content = SafeArea(child: content);

    if (bottomBar == null) return content;
    return Stack(
      fit: StackFit.expand,
      children: [
        content,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                B.space4,
                B.space3,
                B.space4,
                B.space4,
              ),
              child: bottomBar,
            ),
          ),
        ),
      ],
    );
  }
}

class _BibleScrollBehavior extends ScrollBehavior {
  const _BibleScrollBehavior();
  @override
  Widget buildScrollbar(_, Widget child, __) => child;
  @override
  Widget buildOverscrollIndicator(_, Widget child, __) => child;
}
