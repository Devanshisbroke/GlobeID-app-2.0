import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _i = 0;

  static const _slides = [
    _Slide(
        'Travel super-app',
        'Wallet, identity, scanner, planner — one premium experience.',
        Icons.public_rounded),
    _Slide(
        'Boarding-ready',
        'Apple/Google-Wallet-grade boarding passes with real HMAC signing.',
        Icons.confirmation_num_rounded),
    _Slide(
        'Deterministic copilot',
        'Local-first intelligence — never an LLM hallucination.',
        Icons.smart_toy_rounded),
    _Slide(
        'Yours, secured',
        'Biometric vault, audit log, and reduce-transparency.',
        Icons.shield_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) {
                  HapticFeedback.selectionClick();
                  setState(() => _i = i);
                },
                itemCount: _slides.length,
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(AppTokens.space7),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(s.icon,
                            size: 80, color: theme.colorScheme.primary),
                        const SizedBox(height: AppTokens.space5),
                        Text(s.title,
                            style: theme.textTheme.displaySmall,
                            textAlign: TextAlign.center),
                        const SizedBox(height: AppTokens.space3),
                        Text(s.message,
                            style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var d = 0; d < _slides.length; d++)
                  AnimatedContainer(
                    duration: AppTokens.durationSm,
                    width: d == _i ? 22 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: d == _i
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppTokens.space5),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Skip'),
                    ),
                  ),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (_i < _slides.length - 1) {
                          _ctrl.nextPage(
                              duration: AppTokens.durationMd,
                              curve: AppTokens.easeStandard);
                        } else {
                          context.go('/');
                        }
                      },
                      child: Text(
                          _i < _slides.length - 1 ? 'Next' : 'Get started'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide(this.title, this.message, this.icon);
  final String title;
  final String message;
  final IconData icon;
}
