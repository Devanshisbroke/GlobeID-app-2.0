import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../motion/creative_motion.dart';

/// Identity score explainer bottom sheet — shows each factor, weight,
/// current value, and actionable improvement steps.
class ScoreExplainerSheet extends StatelessWidget {
  const ScoreExplainerSheet({super.key, required this.score});
  final int score;

  static Future<void> show(BuildContext context, int score) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ScoreExplainerSheet(score: score),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final factors = _factors(score);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scroll) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTokens.radiusXl)),
        ),
        child: ListView(
            controller: scroll,
            padding: const EdgeInsets.all(AppTokens.space5),
            children: [
              Center(
                  child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppTokens.space4),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.18),
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusFull),
                      ))),
              // Score hero
              Center(
                  child: BreathingGlow(
                color: _scoreColor(score),
                child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [
                        _scoreColor(score),
                        _scoreColor(score).withValues(alpha: 0.6)
                      ]),
                      boxShadow: [
                        BoxShadow(
                            color: _scoreColor(score).withValues(alpha: 0.3),
                            blurRadius: 24)
                      ],
                    ),
                    child: Center(
                        child: AnimatedCounter(
                            value: score,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                fontFeatures: [
                                  FontFeature.tabularFigures()
                                ])))),
              )),
              const SizedBox(height: AppTokens.space3),
              Center(
                  child: Text(_tierLabel(score),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800))),
              Center(
                  child: Text('Identity Trust Score',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5)))),
              const SizedBox(height: AppTokens.space5),
              // Factors
              Text('SCORE FACTORS',
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.4))),
              const SizedBox(height: AppTokens.space3),
              for (final f in factors) _FactorRow(factor: f),
              const SizedBox(height: AppTokens.space5),
              // Weekly sparkline header
              Text('WEEKLY TREND',
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.4))),
              const SizedBox(height: AppTokens.space2),
              SizedBox(
                  height: 48,
                  child: CustomPaint(
                      painter: _SparklinePainter(
                    values: List.generate(
                        8, (i) => score - 12 + i * 2 + (i == 7 ? 4 : 0)),
                    color: _scoreColor(score),
                  ))),
              const SizedBox(height: AppTokens.space4),
              Text('+${((score * 0.06).round())} points this week',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF22C55E),
                      fontWeight: FontWeight.w700)),
            ]),
      ),
    );
  }

  Color _scoreColor(int s) => s >= 80
      ? const Color(0xFF22C55E)
      : s >= 60
          ? const Color(0xFF0EA5E9)
          : s >= 40
              ? const Color(0xFFF59E0B)
              : const Color(0xFFEF4444);
  String _tierLabel(int s) => s >= 80
      ? 'Sovereign'
      : s >= 60
          ? 'Verified'
          : s >= 40
              ? 'Standard'
              : 'Citizen';

  List<_Factor> _factors(int score) => [
        _Factor(
            'Email verified',
            'Email address confirmed',
            score >= 20 ? 1.0 : 0.0,
            Icons.email_rounded,
            const Color(0xFF22C55E),
            null),
        _Factor(
            'Phone verified',
            'Mobile number confirmed',
            score >= 30 ? 1.0 : 0.5,
            Icons.phone_rounded,
            const Color(0xFF0EA5E9),
            score < 30 ? 'Verify your phone number' : null),
        _Factor(
            'Government ID',
            'Passport or national ID scanned',
            score >= 50 ? 1.0 : 0.0,
            Icons.badge_rounded,
            const Color(0xFF8B5CF6),
            score < 50 ? 'Scan your passport' : null),
        _Factor(
            'Biometric',
            'Face ID / fingerprint enrolled',
            score >= 60 ? 1.0 : 0.3,
            Icons.fingerprint_rounded,
            const Color(0xFFEC4899),
            score < 60 ? 'Enable biometric lock' : null),
        _Factor(
            'Travel history',
            'Verified trips completed',
            (score / 1000).clamp(0.0, 1.0),
            Icons.flight_rounded,
            const Color(0xFFF59E0B),
            'Complete more verified trips'),
        _Factor(
            'Network trust',
            'Endorsements from verified users',
            (score / 120).clamp(0.0, 1.0),
            Icons.people_rounded,
            const Color(0xFF14B8A6),
            'Get endorsed by other GlobeID users'),
      ];
}

class _Factor {
  const _Factor(
      this.name, this.desc, this.value, this.icon, this.color, this.action);
  final String name, desc;
  final double value;
  final IconData icon;
  final Color color;
  final String? action;
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({required this.factor});
  final _Factor factor;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
        padding: const EdgeInsets.only(bottom: AppTokens.space3),
        child: Row(children: [
          Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                color: factor.color.withValues(alpha: 0.12),
              ),
              child: Icon(factor.icon, color: factor.color, size: 18)),
          const SizedBox(width: AppTokens.space3),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Text(factor.name,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  if (factor.value >= 1.0)
                    Icon(Icons.check_circle_rounded,
                        color: factor.color, size: 14),
                ]),
                const SizedBox(height: 2),
                ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: factor.value,
                      backgroundColor:
                          theme.colorScheme.onSurface.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation(factor.color),
                      minHeight: 4,
                    )),
                if (factor.action != null) ...[
                  const SizedBox(height: 2),
                  Text(factor.action!,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: factor.color, fontWeight: FontWeight.w600)),
                ],
              ])),
        ]));
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});
  final List<int> values;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final mn = values.reduce((a, b) => a < b ? a : b).toDouble();
    final mx = values.reduce((a, b) => a > b ? a : b).toDouble();
    final range = mx - mn == 0 ? 1.0 : mx - mn;
    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height - ((values[i] - mn) / range) * size.height * 0.85;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.2),
                color.withValues(alpha: 0.0)
              ]).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
    // Draw last dot
    final lastX = size.width;
    final lastY =
        size.height - ((values.last - mn) / range) * size.height * 0.85;
    canvas.drawCircle(Offset(lastX, lastY), 4, Paint()..color = color);
    canvas.drawCircle(
        Offset(lastX, lastY), 6, Paint()..color = color.withValues(alpha: 0.2));
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => true;
}
