import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/emotional_palette.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium/premium.dart';

/// Premium showcase — a single screen that exercises every Wave 1
/// foundation widget so QA / design can audit the toolkit at a
/// glance.
///
/// Sections: ambient layer + magnetic CTA + kinetic stack + spatial
/// depth + sensor pendulum + departure board + contextual surfaces +
/// liquid wave + premium loading + cinematic route hero placeholder.
class PremiumShowcaseScreen extends StatelessWidget {
  const PremiumShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageScaffold(
      title: 'Premium showcase',
      subtitle: 'Wave 1 foundation widgets',
      body: Stack(
        children: [
          const Positioned.fill(child: AmbientLightingLayer()),
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space5,
              0,
              AppTokens.space5,
              AppTokens.space9 + 16,
            ),
            children: [
              const _SectionLabel(title: 'Magnetic CTAs'),
              Row(
                children: [
                  Expanded(
                    child: MagneticButton(
                      label: 'Send',
                      icon: Icons.arrow_outward_rounded,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: AppTokens.space2),
                  Expanded(
                    child: MagneticButton(
                      label: 'Convert',
                      icon: Icons.swap_horiz_rounded,
                      compact: true,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.30),
                          theme.colorScheme.primary.withValues(alpha: 0.10),
                        ],
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space5),

              const _SectionLabel(title: 'Liquid wave surface'),
              LiquidWaveSurface(
                progress: 0.62,
                tone: theme.colorScheme.primary,
                height: 60,
              ),
              const SizedBox(height: AppTokens.space5),

              const _SectionLabel(title: 'Departure board flap'),
              ContextualSurface(
                child: Center(
                  child: DepartureBoardText(
                    text: 'GLOBE 7411',
                    style: AirportFontStack.board(context, size: 32),
                    tone: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space5),

              const _SectionLabel(title: 'Sensor pendulum + spatial depth'),
              SizedBox(
                height: 240,
                child: SpatialDepthLayer(
                  layers: [
                    SpatialLayer(
                      depth: 1.0,
                      haze: true,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface
                              .withValues(alpha: 0.55),
                          borderRadius:
                              BorderRadius.circular(AppTokens.radius2xl),
                        ),
                      ),
                    ),
                    SpatialLayer(
                      depth: 0.55,
                      child: Center(
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(AppTokens.radius2xl),
                          ),
                        ),
                      ),
                    ),
                    SpatialLayer(
                      depth: 0.0,
                      child: Center(
                        child: SensorPendulum(
                          translation: 8,
                          rotation: 0.04,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(
                                  AppTokens.radius2xl),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.4),
                                  blurRadius: 30,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Icon(Icons.bolt_rounded,
                                size: 36, color: theme.colorScheme.primary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.space5),

              const _SectionLabel(title: 'Kinetic card stack'),
              KineticCardStack(
                itemCount: 6,
                builder: (_, i, p) => ContextualSurface(
                  context: EmotionalContext.values[i %
                      EmotionalContext.values.length],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('CARD ${i + 1}',
                          style:
                              AirportFontStack.iata(context, size: 14)),
                      const SizedBox(height: 6),
                      Text('Stacked deck with sensor tilt and snap.',
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space5),

              const _SectionLabel(title: 'Contextual surface gallery'),
              for (final ctx in EmotionalContext.values) ...[
                ContextualSurface(
                  context: ctx,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 32,
                        decoration: BoxDecoration(
                          color: EmotionalPalette.shiftFor(ctx)
                                  .accentOverride ??
                              theme.colorScheme.primary,
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusFull),
                        ),
                      ),
                      const SizedBox(width: AppTokens.space3),
                      Text(ctx.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.space2),
              ],

              const SizedBox(height: AppTokens.space5),
              const _SectionLabel(title: 'Premium loading'),
              const PremiumLoadingSequence(
                  size: 96, caption: 'Securing your trip…'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppTokens.space5,
        bottom: AppTokens.space2,
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 18,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
            ),
          ),
          const SizedBox(width: AppTokens.space2),
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}
