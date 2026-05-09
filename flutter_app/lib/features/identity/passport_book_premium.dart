import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/premium/premium.dart';
import '../../widgets/premium_effects.dart';

/// Premium passport hero — a thick, luxurious passport book that
/// breathes under the gyro and shimmers a holographic foil.
///
/// Drop in any identity hub or country profile screen to broadcast
/// "this is the real document, signed and sealed".
class PassportBookPremium extends StatelessWidget {
  const PassportBookPremium({
    super.key,
    required this.country,
    required this.holderName,
    required this.tier,
    this.crest = '✦',
    this.sealed = true,
    this.heroTag,
  });

  final String country;
  final String holderName;
  final String tier;
  final String crest;
  final bool sealed;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final innerRadius = BorderRadius.circular(AppTokens.radius2xl);

    final faceContent = Container(
      padding: const EdgeInsets.all(AppTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space3,
                  vertical: AppTokens.space1,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Text(
                  'IDENTITY · ${tier.toUpperCase()}',
                  style: AirportFontStack.gate(context, size: 10)
                      .copyWith(color: Colors.white),
                ),
              ),
              const Spacer(),
              Text(
                crest,
                style: TextStyle(
                  fontSize: 28,
                  color: Colors.white.withValues(alpha: 0.92),
                  shadows: [
                    Shadow(
                      blurRadius: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space5),
          Text(country.toUpperCase(),
              style: AirportFontStack.iata(context, size: 28)
                  .copyWith(color: Colors.white)),
          const SizedBox(height: AppTokens.space1),
          Text('PASSPORT',
              style: AirportFontStack.gate(context, size: 12)
                  .copyWith(color: Colors.white.withValues(alpha: 0.65))),
          const Spacer(),
          Text('BEARER',
              style: AirportFontStack.gate(context, size: 9)
                  .copyWith(color: Colors.white.withValues(alpha: 0.55))),
          const SizedBox(height: 2),
          Text(
            holderName,
            style: AirportFontStack.flightNumber(context, size: 16)
                .copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppTokens.space3),
          if (sealed)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space3,
                vertical: AppTokens.space2,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFD4AF37), Color(0xFFFFE7AC)],
                ),
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              ),
              child: Text('SEALED · VERIFIED',
                  style: AirportFontStack.gate(context, size: 10)
                      .copyWith(color: const Color(0xFF231A04))),
            ),
        ],
      ),
    );

    final base = ClipRRect(
      borderRadius: innerRadius,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF132034),
                  const Color(0xFF1B2949),
                  theme.colorScheme.primary.withValues(alpha: 0.42),
                ],
              ),
              borderRadius: innerRadius,
            ),
          ),
          HolographicFoil(
            intensity: 0.9,
            borderRadius: innerRadius,
            child: TiltShimmer(child: faceContent),
          ),
        ],
      ),
    );

    Widget body = AspectRatio(
      aspectRatio: 5 / 7,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: innerRadius,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.30),
              blurRadius: 40,
              offset: const Offset(0, 30),
            ),
          ],
        ),
        child: DepthCard(
          maxRotation: 6,
          elevation: 14,
          borderRadius: innerRadius,
          child: base,
        ),
      ),
    );

    body = SensorPendulum(
      translation: 4,
      rotation: 0.018,
      weight: 1.4,
      child: body,
    );

    if (heroTag != null) {
      body = Hero(tag: heroTag!, child: body);
    }
    return body;
  }
}
