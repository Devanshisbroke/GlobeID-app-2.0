import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/premium/premium.dart';

/// A premium service card surface — used by the Services hub for
/// hotels / flights / eSIM / visa / lounge / activities. Pairs a
/// vivid gradient face with a sensor pendulum, a magnetic press
/// affordance, and a contextual-surface chrome.
class PremiumServiceCard extends StatelessWidget {
  const PremiumServiceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    this.gradient,
    this.tag,
    this.heroTag,
    this.onTap,
    this.height = 168,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tone;
  final Gradient? gradient;
  final String? tag;
  final Object? heroTag;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = SensorPendulum(
      translation: 4,
      rotation: 0.012,
      child: MagneticPressable(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTokens.radius2xl),
          child: Container(
            height: height,
            padding: const EdgeInsets.all(AppTokens.space4),
            decoration: BoxDecoration(
              gradient: gradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tone,
                      Color.lerp(tone, Colors.black, 0.4)!,
                    ],
                  ),
              borderRadius: BorderRadius.circular(AppTokens.radius2xl),
              boxShadow: [
                BoxShadow(
                  color: tone.withValues(alpha: 0.42),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -32,
                  bottom: -32,
                  child: Opacity(
                    opacity: 0.18,
                    child: Icon(icon, size: 192, color: Colors.white),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTokens.space2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusFull),
                          ),
                          child: Icon(icon, size: 20, color: Colors.white),
                        ),
                        const Spacer(),
                        if (tag != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTokens.space2 + 2,
                              vertical: AppTokens.space1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                  AppTokens.radiusFull),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              tag!.toUpperCase(),
                              style: AirportFontStack.gate(context, size: 10)
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        )),
                    const SizedBox(height: AppTokens.space1),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                        )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (heroTag != null) {
      return Hero(tag: heroTag!, child: body);
    }
    return body;
  }
}
