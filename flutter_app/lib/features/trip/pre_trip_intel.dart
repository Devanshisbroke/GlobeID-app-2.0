import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/section_header.dart';

/// Pre-trip intelligence card with collapsible sections.
///
/// Sections: Visa | Weather | Packing | Currency | Connectivity
/// Each pulls from domain modules. Designed for the trip detail screen.
class PreTripIntel extends StatelessWidget {
  const PreTripIntel({
    super.key,
    required this.destination,
    required this.sections,
  });

  final String destination;
  final List<IntelSection> sections;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Pre-trip intel',
          subtitle: 'Everything you need for $destination',
        ),
        for (var i = 0; i < sections.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space2),
            child: _IntelSectionCard(section: sections[i])
                .animate()
                .fadeIn(
                  duration: AppTokens.durationMd,
                  delay: Duration(milliseconds: 80 * i),
                  curve: AppTokens.easeOutSoft,
                )
                .slideY(begin: 0.03, end: 0),
          ),
      ],
    );
  }
}

class _IntelSectionCard extends StatefulWidget {
  const _IntelSectionCard({required this.section});
  final IntelSection section;

  @override
  State<_IntelSectionCard> createState() => _IntelSectionCardState();
}

class _IntelSectionCardState extends State<_IntelSectionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sec = widget.section;

    return GlassSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(AppTokens.radiusXl),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      color: sec.tone.withValues(alpha: 0.14),
                    ),
                    child: Icon(sec.icon, size: 18, color: sec.tone),
                  ),
                  const SizedBox(width: AppTokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sec.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (sec.summary.isNotEmpty)
                          Text(
                            sec.summary,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.55),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (sec.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusFull),
                        color: sec.badgeColor.withValues(alpha: 0.14),
                      ),
                      child: Text(
                        sec.badge!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: sec.badgeColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  const SizedBox(width: AppTokens.space2),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: AppTokens.durationSm,
                    child: Icon(
                      Icons.expand_more_rounded,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.40),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space4,
                0,
                AppTokens.space4,
                AppTokens.space4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: AppTokens.space3),
                  for (final item in sec.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppTokens.space2),
                      child: _IntelItem(item: item),
                    ),
                  if (sec.actionRoute != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTokens.space2),
                      child: TextButton.icon(
                        onPressed: () => context.push(sec.actionRoute!),
                        icon: const Icon(Icons.open_in_new_rounded, size: 14),
                        label: Text(sec.actionLabel ?? 'Open'),
                        style: TextButton.styleFrom(
                          foregroundColor: sec.tone,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: AppTokens.durationSm,
          ),
        ],
      ),
    );
  }
}

class _IntelItem extends StatelessWidget {
  const _IntelItem({required this.item});
  final IntelItemData item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            item.checked ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: item.checked
                ? const Color(0xFF22C55E)
                : theme.colorScheme.onSurface.withValues(alpha: 0.30),
          ),
        ),
        const SizedBox(width: AppTokens.space2),
        Expanded(
          child: Text(
            item.label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              decoration: item.checked ? TextDecoration.lineThrough : null,
              color: item.checked
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.40)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

class IntelSection {
  const IntelSection({
    required this.title,
    required this.summary,
    required this.icon,
    required this.items,
    this.tone = const Color(0xFF0EA5E9),
    this.badge,
    this.badgeColor = const Color(0xFF22C55E),
    this.actionRoute,
    this.actionLabel,
  });

  final String title;
  final String summary;
  final IconData icon;
  final List<IntelItemData> items;
  final Color tone;
  final String? badge;
  final Color badgeColor;
  final String? actionRoute;
  final String? actionLabel;

  /// Demo sections for development.
  static List<IntelSection> demo(String destination) => [
        IntelSection(
          title: 'Visa & Entry',
          summary: 'Visa-free for 90 days',
          icon: Icons.assignment_ind_rounded,
          tone: const Color(0xFF10B981),
          badge: 'OK',
          badgeColor: const Color(0xFF22C55E),
          actionRoute: '/identity',
          actionLabel: 'Check documents',
          items: [
            const IntelItemData('Valid passport (6+ months)', true),
            const IntelItemData('No visa required for stays < 90 days', true),
            IntelItemData('Travel insurance recommended', false),
          ],
        ),
        IntelSection(
          title: 'Weather',
          summary: '24°C · Partly cloudy',
          icon: Icons.wb_sunny_rounded,
          tone: const Color(0xFFD97706),
          items: [
            IntelItemData('Avg high: 24°C / Low: 16°C', false),
            IntelItemData('Rain chance: 20%', false),
            IntelItemData('Pack light layers + sunscreen', false),
          ],
        ),
        IntelSection(
          title: 'Packing',
          summary: '3 of 8 items packed',
          icon: Icons.luggage_rounded,
          tone: const Color(0xFF8B5CF6),
          badge: '3/8',
          badgeColor: const Color(0xFFF59E0B),
          actionRoute: '/packing',
          actionLabel: 'Open packing list',
          items: [
            const IntelItemData('Passport', true),
            const IntelItemData('Phone charger + adapter', true),
            const IntelItemData('Medications', true),
            IntelItemData('Sunscreen SPF 50+', false),
            IntelItemData('Light jacket', false),
            IntelItemData('Comfortable walking shoes', false),
          ],
        ),
        IntelSection(
          title: 'Currency',
          summary: 'Local currency ready',
          icon: Icons.currency_exchange_rounded,
          tone: const Color(0xFF0EA5E9),
          actionRoute: '/multi-currency',
          actionLabel: 'Exchange rates',
          items: [
            IntelItemData('1 USD = 0.92 EUR', false),
            IntelItemData('Cards widely accepted', false),
            IntelItemData('ATMs available at airport', false),
          ],
        ),
        IntelSection(
          title: 'Connectivity',
          summary: 'eSIM available',
          icon: Icons.signal_cellular_alt_rounded,
          tone: const Color(0xFF06B6D4),
          actionRoute: '/esim',
          actionLabel: 'Get eSIM',
          items: [
            IntelItemData('5G coverage in major cities', false),
            IntelItemData('eSIM: \$8/week unlimited data', false),
            IntelItemData('Free WiFi at hotels and cafés', false),
          ],
        ),
      ];
}

class IntelItemData {
  const IntelItemData(this.label, this.checked);
  final String label;
  final bool checked;
}
