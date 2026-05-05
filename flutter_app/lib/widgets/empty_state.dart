import 'package:flutter/material.dart';

import '../app/theme/app_tokens.dart';

/// Mirrors `<EmptyState />` from the React app — tone + CTA + tertiary CTA.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.tone,
    this.cta,
    this.onCta,
    this.tertiary,
    this.onTertiary,
  });

  final String title;
  final String message;
  final IconData? icon;
  final Color? tone;
  final String? cta;
  final VoidCallback? onCta;
  final String? tertiary;
  final VoidCallback? onTertiary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tone ?? theme.colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTokens.radius2xl),
              ),
              child: Icon(icon ?? Icons.auto_awesome_rounded,
                  color: color, size: 32),
            ),
            const SizedBox(height: AppTokens.space5),
            Text(title,
                style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppTokens.space2),
            Text(message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center),
            if (cta != null) ...[
              const SizedBox(height: AppTokens.space5),
              FilledButton(onPressed: onCta, child: Text(cta!)),
            ],
            if (tertiary != null) ...[
              const SizedBox(height: AppTokens.space2),
              TextButton(onPressed: onTertiary, child: Text(tertiary!)),
            ],
          ],
        ),
      ),
    );
  }
}
