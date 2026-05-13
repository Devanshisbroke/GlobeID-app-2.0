import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/api/api_provider.dart';
import '../../domain/airports.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/skeletons.dart';
import '../../widgets/toast.dart';

final plannerListProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.read(globeIdApiProvider).plannerList();
});

/// Planner v3 — flagship multi-step wizard with reorderable list view.
///
/// The list is the default view. Tapping `+ Plan a trip` opens a
/// 5-step modal wizard (destination → dates → travellers → add-ons
/// → review) with cinematic step transitions, validation, haptics,
/// and a final confirm that POSTs to the planner API and refreshes
/// the list.
class PlannerScreen extends ConsumerWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTrips = ref.watch(plannerListProvider);
    return PageScaffold(
      title: 'Planner',
      subtitle: 'Sketch and reorder upcoming trips',
      actions: [
        IconButton(
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Plan a trip',
          onPressed: () => _openWizard(context, ref),
        ),
      ],
      body: asyncTrips.when(
        loading: () => const SkeletonList(count: 4, itemHeight: 96),
        error: (e, _) => EmptyState(
          title: 'Planner unavailable',
          message: e.toString(),
          icon: Icons.cloud_off_rounded,
        ),
        data: (trips) {
          if (trips.isEmpty) {
            return _PlannerEmpty(onPlan: () => _openWizard(context, ref));
          }
          final list = trips.cast<Map<String, dynamic>>();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space3),
                child: _PlanCallToActionStrip(
                  onPlan: () => _openWizard(context, ref),
                  count: list.length,
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  physics: const BouncingScrollPhysics(),
                  onReorder: (_, __) {
                    HapticFeedback.lightImpact();
                  },
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final t = list[i];
                    return Padding(
                      key: ValueKey(t['id']),
                      padding: const EdgeInsets.only(bottom: AppTokens.space3),
                      child: AnimatedAppearance(
                        delay: Duration(milliseconds: 50 * i),
                        child: _PlanRow(index: i + 1, trip: t),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openWizard(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    final result = await Navigator.of(context).push<TripPlanDraft>(
      PageRouteBuilder<TripPlanDraft>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        transitionDuration: AppTokens.durationLg,
        reverseTransitionDuration: AppTokens.durationMd,
        pageBuilder: (_, anim, __) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: AppTokens.easeOutSoft),
          child: const _PlannerWizard(),
        ),
      ),
    );
    if (result == null) return;
    if (!context.mounted) return;
    try {
      await ref.read(globeIdApiProvider).plannerUpsert(result.toJson());
      // ignore: unused_result
      ref.refresh(plannerListProvider);
      if (!context.mounted) return;
      AppToast.show(
        context,
        title: 'Trip added',
        message: 'Saved to planner',
        tone: AppToastTone.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      AppToast.show(
        context,
        title: "Couldn't save",
        message: '$e',
        tone: AppToastTone.danger,
      );
    }
  }
}

class _PlannerEmpty extends StatelessWidget {
  const _PlannerEmpty({required this.onPlan});
  final VoidCallback onPlan;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.4),
                      theme.colorScheme.secondary.withValues(alpha: 0.16),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: AppTokens.space5),
              Text(
                'Plan your next trip',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppTokens.space2),
              Text(
                'Sketch a trip in 5 steps. We\'ll pre-fill suggestions from '
                'your travel history and frequent routes.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppTokens.space5),
              CinematicButton(
                label: 'Start planning',
                icon: Icons.bolt_rounded,
                onPressed: onPlan,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCallToActionStrip extends StatelessWidget {
  const _PlanCallToActionStrip({required this.onPlan, required this.count});
  final VoidCallback onPlan;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space3),
      gradient: LinearGradient(
        colors: [
          theme.colorScheme.primary.withValues(alpha: 0.20),
          theme.colorScheme.secondary.withValues(alpha: 0.06),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: theme.brightness == Brightness.dark
                  ? LinearGradient(colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ])
                  : LinearGradient(colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ]),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count plan${count == 1 ? '' : 's'} in flight',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Tap to sketch a new one',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
          Pressable(
            onTap: onPlan,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.index, required this.trip});
  final int index;
  final Map<String, dynamic> trip;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pinned = (trip['pinned'] as bool?) ?? false;
    final budget = (trip['budget'] as num?)?.toInt();
    final currency = (trip['currency'] ?? 'USD').toString();
    final title = (trip['title'] ?? trip['name'] ?? 'Trip').toString();
    final subtitle = (trip['subtitle'] ?? trip['date'] ?? '').toString();
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.6),
                ],
              ),
              boxShadow: AppTokens.shadowSm(tint: theme.colorScheme.primary),
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (pinned) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.push_pin_rounded,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ],
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                if (budget != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 12,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$currency ${budget.toString()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
            ),
            child: Icon(
              Icons.drag_handle_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Wizard
// ─────────────────────────────────────────────────────────────────

/// Mutable draft passed through the wizard pages.
class TripPlanDraft {
  TripPlanDraft();

  Airport? destination;
  DateTimeRange? dates;
  int travellers = 1;
  String cabin = 'Economy';
  Set<String> addons = <String>{};
  String? notes;

  String get title => destination == null ? 'New plan' : destination!.city;
  String get subtitle {
    final parts = <String>[];
    if (dates != null) {
      parts.add(_formatDateRange(dates!));
    }
    parts.add('$travellers traveller${travellers == 1 ? '' : 's'}');
    parts.add(cabin);
    return parts.join(' · ');
  }

  Map<String, dynamic> toJson() => {
        'id': 'plan-${DateTime.now().millisecondsSinceEpoch}',
        'title':
            destination == null ? 'New plan' : '${destination!.city} · planned',
        'subtitle': subtitle,
        'destination': destination?.iata,
        'startDate': dates?.start.toIso8601String(),
        'endDate': dates?.end.toIso8601String(),
        'travellers': travellers,
        'cabin': cabin,
        'addons': addons.toList(),
        'pinned': false,
        'budget': _estimatedBudget(),
        'currency': 'USD',
        'notes': notes,
      };

  int _estimatedBudget() {
    var base = 1500;
    base += (dates?.duration.inDays ?? 5) * 220;
    if (cabin == 'Business') base = (base * 2.4).round();
    if (cabin == 'First') base = (base * 4.5).round();
    base *= travellers;
    if (addons.contains('insurance')) base += 180;
    if (addons.contains('lounge')) base += 95;
    if (addons.contains('esim')) base += 45;
    if (addons.contains('transfer')) base += 130;
    return base;
  }
}

String _formatDateRange(DateTimeRange r) {
  String two(int n) => n.toString().padLeft(2, '0');
  String mmdd(DateTime d) => '${two(d.month)}/${two(d.day)}';
  return '${mmdd(r.start)} – ${mmdd(r.end)}';
}

class _PlannerWizard extends StatefulWidget {
  const _PlannerWizard();

  @override
  State<_PlannerWizard> createState() => _PlannerWizardState();
}

class _PlannerWizardState extends State<_PlannerWizard> {
  final _draft = TripPlanDraft();
  int _step = 0;

  static const _titles = [
    'Where to?',
    'When?',
    'Who\'s coming?',
    'Add-ons',
    'Review',
  ];

  static const _subtitles = [
    'Search or pick a featured destination',
    'Select your travel window',
    'Travellers + cabin class',
    'Insurance · lounge · eSIM · transfer',
    'Confirm and add to planner',
  ];

  bool _canAdvance() {
    switch (_step) {
      case 0:
        return _draft.destination != null;
      case 1:
        return _draft.dates != null;
      case 2:
        return _draft.travellers >= 1;
      case 3:
        return true;
      case 4:
        return true;
      default:
        return false;
    }
  }

  void _next() {
    if (!_canAdvance()) {
      HapticFeedback.lightImpact();
      return;
    }
    HapticFeedback.selectionClick();
    if (_step == _titles.length - 1) {
      Navigator.of(context).pop(_draft);
      return;
    }
    setState(() => _step += 1);
  }

  void _back() {
    HapticFeedback.selectionClick();
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step -= 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: isDark
          ? Colors.black.withValues(alpha: 0.86)
          : Colors.white.withValues(alpha: 0.96),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space5),
          child: Column(
            children: [
              _StepHeader(
                step: _step,
                total: _titles.length,
                title: _titles[_step],
                subtitle: _subtitles[_step],
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: AppTokens.space4),
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppTokens.durationMd,
                  switchInCurve: AppTokens.easeOutSoft,
                  transitionBuilder: (child, anim) {
                    final dx = Tween<Offset>(
                      begin: const Offset(0.06, 0),
                      end: Offset.zero,
                    ).animate(anim);
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(position: dx, child: child),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildStep(_step),
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(_step == 0 ? 'Cancel' : 'Back'),
                    ),
                  ),
                  const SizedBox(width: AppTokens.space3),
                  Expanded(
                    flex: 2,
                    child: CinematicButton(
                      label: _step == _titles.length - 1
                          ? 'Add to planner'
                          : 'Continue',
                      icon: _step == _titles.length - 1
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      onPressed: _canAdvance() ? _next : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int s) {
    switch (s) {
      case 0:
        return _DestinationStep(
          draft: _draft,
          onChanged: () => setState(() {}),
        );
      case 1:
        return _DatesStep(
          draft: _draft,
          onChanged: () => setState(() {}),
        );
      case 2:
        return _TravellersStep(
          draft: _draft,
          onChanged: () => setState(() {}),
        );
      case 3:
        return _AddonsStep(
          draft: _draft,
          onChanged: () => setState(() {}),
        );
      case 4:
        return _ReviewStep(draft: _draft);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.step,
    required this.total,
    required this.title,
    required this.subtitle,
    required this.onClose,
  });
  final int step;
  final int total;
  final String title;
  final String subtitle;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                color: theme.colorScheme.primary.withValues(alpha: 0.16),
              ),
              child: Text(
                'STEP ${step + 1} / $total',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded),
              onPressed: onClose,
            ),
          ],
        ),
        const SizedBox(height: AppTokens.space3),
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
          ),
        ),
        const SizedBox(height: AppTokens.space3),
        // Step progress dots.
        Row(
          children: [
            for (var i = 0; i < total; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: AppTokens.durationSm,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: i <= step
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.10),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// Step 1 — destination
class _DestinationStep extends StatefulWidget {
  const _DestinationStep({required this.draft, required this.onChanged});
  final TripPlanDraft draft;
  final VoidCallback onChanged;
  @override
  State<_DestinationStep> createState() => _DestinationStepState();
}

class _DestinationStepState extends State<_DestinationStep> {
  String _q = '';

  static const _featured = ['NRT', 'CDG', 'JFK', 'DXB', 'SIN', 'BCN', 'SYD'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lowerQ = _q.toLowerCase();
    final results = _q.isEmpty
        ? <Airport>[]
        : kAirports
            .where((a) {
              return a.iata.toLowerCase().contains(lowerQ) ||
                  a.city.toLowerCase().contains(lowerQ) ||
                  a.country.toLowerCase().contains(lowerQ);
            })
            .take(20)
            .toList();
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        TextField(
          autofocus: true,
          onChanged: (v) => setState(() => _q = v),
          decoration: InputDecoration(
            hintText: 'Search city or airport',
            prefixIcon: const Icon(Icons.search_rounded),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          ),
        ),
        const SizedBox(height: AppTokens.space4),
        if (_q.isEmpty) ...[
          Text(
            'FEATURED',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppTokens.space2,
            crossAxisSpacing: AppTokens.space2,
            childAspectRatio: 2.4,
            children: [
              for (final iata in _featured)
                _FeaturedCard(
                  iata: iata,
                  selected: widget.draft.destination?.iata == iata,
                  onTap: () {
                    final a = getAirport(iata);
                    if (a == null) return;
                    HapticFeedback.selectionClick();
                    widget.draft.destination = a;
                    widget.onChanged();
                  },
                ),
            ],
          ),
        ] else ...[
          for (final a in results)
            _AirportRow(
              airport: a,
              selected: widget.draft.destination?.iata == a.iata,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.draft.destination = a;
                widget.onChanged();
              },
            ),
        ],
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.iata,
    required this.selected,
    required this.onTap,
  });
  final String iata;
  final bool selected;
  final VoidCallback onTap;

  static const Map<String, String> _flagFor = {
    'NRT': '🇯🇵',
    'CDG': '🇫🇷',
    'JFK': '🇺🇸',
    'DXB': '🇦🇪',
    'SIN': '🇸🇬',
    'BCN': '🇪🇸',
    'SYD': '🇦🇺',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final airport = getAirport(iata);
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationSm,
        padding: const EdgeInsets.all(AppTokens.space3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          gradient: selected
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                )
              : LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.16),
                    theme.colorScheme.primary.withValues(alpha: 0.04),
                  ],
                ),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(
              alpha: selected ? 0.0 : 0.20,
            ),
            width: 0.6,
          ),
        ),
        child: Row(
          children: [
            Text(_flagFor[iata] ?? '🌍', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    iata,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color:
                          selected ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    airport?.city ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.85)
                          : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _AirportRow extends StatelessWidget {
  const _AirportRow({
    required this.airport,
    required this.selected,
    required this.onTap,
  });
  final Airport airport;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTokens.space2),
        padding: const EdgeInsets.all(AppTokens.space3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.18)
              : theme.colorScheme.onSurface.withValues(alpha: 0.04),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.40)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              alignment: Alignment.center,
              child: Text(
                airport.iata,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    airport.city,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${airport.name} · ${airport.country}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle_rounded,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

// Step 2 — dates
class _DatesStep extends StatefulWidget {
  const _DatesStep({required this.draft, required this.onChanged});
  final TripPlanDraft draft;
  final VoidCallback onChanged;
  @override
  State<_DatesStep> createState() => _DatesStepState();
}

class _DatesStepState extends State<_DatesStep> {
  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      initialDateRange: widget.draft.dates ??
          DateTimeRange(
            start: now.add(const Duration(days: 30)),
            end: now.add(const Duration(days: 37)),
          ),
    );
    if (picked == null || !mounted) return;
    HapticFeedback.lightImpact();
    widget.draft.dates = picked;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dates = widget.draft.dates;
    final quickPicks = <(String, int)>[
      ('Long weekend', 4),
      ('1 week', 7),
      ('2 weeks', 14),
      ('1 month', 30),
    ];
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        Pressable(
          onTap: _pickRange,
          child: PremiumCard(
            padding: const EdgeInsets.all(AppTokens.space5),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.18),
                theme.colorScheme.secondary.withValues(alpha: 0.04),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'TRAVEL WINDOW',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.space3),
                Text(
                  dates == null ? 'Tap to pick' : _formatDateRange(dates),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                if (dates != null)
                  Text(
                    '${dates.duration.inDays} day${dates.duration.inDays == 1 ? '' : 's'}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.66),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTokens.space4),
        Text(
          'QUICK PICKS',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: AppTokens.space2),
        Wrap(
          spacing: AppTokens.space2,
          runSpacing: AppTokens.space2,
          children: [
            for (final pick in quickPicks)
              Pressable(
                onTap: () {
                  HapticFeedback.selectionClick();
                  final start = DateTime.now().add(const Duration(days: 14));
                  widget.draft.dates = DateTimeRange(
                    start: start,
                    end: start.add(Duration(days: pick.$2)),
                  );
                  widget.onChanged();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  ),
                  child: Text(
                    pick.$1,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// Step 3 — travellers + cabin
class _TravellersStep extends StatelessWidget {
  const _TravellersStep({required this.draft, required this.onChanged});
  final TripPlanDraft draft;
  final VoidCallback onChanged;

  static const _cabins = ['Economy', 'Premium', 'Business', 'First'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        PremiumCard(
          padding: const EdgeInsets.all(AppTokens.space5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.group_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'TRAVELLERS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space3),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StepperButton(
                    icon: Icons.remove_rounded,
                    onTap: () {
                      if (draft.travellers > 1) {
                        HapticFeedback.selectionClick();
                        draft.travellers -= 1;
                        onChanged();
                      }
                    },
                  ),
                  Text(
                    '${draft.travellers}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  _StepperButton(
                    icon: Icons.add_rounded,
                    onTap: () {
                      if (draft.travellers < 9) {
                        HapticFeedback.selectionClick();
                        draft.travellers += 1;
                        onChanged();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space4),
        Text(
          'CABIN CLASS',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: AppTokens.space2),
        for (final c in _cabins)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space2),
            child: Pressable(
              onTap: () {
                HapticFeedback.selectionClick();
                draft.cabin = c;
                onChanged();
              },
              child: Container(
                padding: const EdgeInsets.all(AppTokens.space3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                  color: draft.cabin == c
                      ? theme.colorScheme.primary.withValues(alpha: 0.16)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.04),
                  border: Border.all(
                    color: draft.cabin == c
                        ? theme.colorScheme.primary.withValues(alpha: 0.40)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _iconForCabin(c),
                      color: draft.cabin == c
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: AppTokens.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _descForCabin(c),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (draft.cabin == c)
                      Icon(
                        Icons.check_circle_rounded,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  IconData _iconForCabin(String c) => switch (c) {
        'Economy' => Icons.airline_seat_recline_normal_rounded,
        'Premium' => Icons.airline_seat_recline_extra_rounded,
        'Business' => Icons.airline_seat_flat_rounded,
        'First' => Icons.local_fire_department_rounded,
        _ => Icons.flight_class_rounded,
      };
  String _descForCabin(String c) => switch (c) {
        'Economy' => 'Standard seat, included carry-on',
        'Premium' => 'Wider seat, more legroom',
        'Business' => 'Lie-flat, lounge access',
        'First' => 'Suite, chauffeur, priority',
        _ => '',
      };
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
        ),
        child: Icon(icon, size: 28),
      ),
    );
  }
}

// Step 4 — addons
class _AddonsStep extends StatelessWidget {
  const _AddonsStep({required this.draft, required this.onChanged});
  final TripPlanDraft draft;
  final VoidCallback onChanged;

  static const _options = [
    (
      'insurance',
      'Travel insurance',
      'Trip cancellation, medical, lost luggage',
      Icons.shield_rounded,
      Color(0xFF06B6D4),
    ),
    (
      'lounge',
      'Lounge access',
      'Pre-flight relaxation across 1,300+ lounges',
      Icons.weekend_rounded,
      Color(0xFF7C3AED),
    ),
    (
      'esim',
      'eSIM data plan',
      '5 GB at destination, instant activation',
      Icons.sim_card_rounded,
      Color(0xFF10B981),
    ),
    (
      'transfer',
      'Airport transfer',
      'Black-car arrival pickup',
      Icons.directions_car_rounded,
      Color(0xFFF59E0B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        for (final o in _options)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.space3),
            child: _AddonRow(
              id: o.$1,
              title: o.$2,
              subtitle: o.$3,
              icon: o.$4,
              tone: o.$5,
              selected: draft.addons.contains(o.$1),
              onToggle: () {
                HapticFeedback.selectionClick();
                if (draft.addons.contains(o.$1)) {
                  draft.addons.remove(o.$1);
                } else {
                  draft.addons.add(o.$1);
                }
                onChanged();
              },
            ),
          ),
      ],
    );
  }
}

class _AddonRow extends StatelessWidget {
  const _AddonRow({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.selected,
    required this.onToggle,
  });
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tone;
  final bool selected;
  final VoidCallback onToggle;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: AppTokens.durationSm,
        padding: const EdgeInsets.all(AppTokens.space4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusXl),
          gradient: selected
              ? LinearGradient(
                  colors: [
                    tone.withValues(alpha: 0.32),
                    tone.withValues(alpha: 0.10),
                  ],
                )
              : LinearGradient(
                  colors: [
                    tone.withValues(alpha: 0.08),
                    tone.withValues(alpha: 0.02),
                  ],
                ),
          border: Border.all(
            color: tone.withValues(alpha: selected ? 0.45 : 0.18),
            width: 0.6,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [tone, tone.withValues(alpha: 0.6)],
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.66),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: AppTokens.durationSm,
              child: selected
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      key: ValueKey('on'),
                    )
                  : Icon(
                      Icons.add_circle_outline_rounded,
                      key: const ValueKey('off'),
                      color: tone,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Step 5 — review
class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.draft});
  final TripPlanDraft draft;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budget = draft.toJson()['budget'] as int;
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        PremiumCard(
          padding: const EdgeInsets.all(AppTokens.space5),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.36),
              theme.colorScheme.secondary.withValues(alpha: 0.10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.bolt_rounded, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  'YOUR PLAN',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
              ]),
              const SizedBox(height: AppTokens.space3),
              Text(
                draft.destination?.city ?? '—',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                draft.subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.space4),
        _ReviewRow(
          label: 'Destination',
          value: draft.destination == null
              ? '—'
              : '${draft.destination!.city} (${draft.destination!.iata})',
          icon: Icons.location_on_outlined,
        ),
        _ReviewRow(
          label: 'Dates',
          value: draft.dates == null ? '—' : _formatDateRange(draft.dates!),
          icon: Icons.event_rounded,
        ),
        _ReviewRow(
          label: 'Travellers',
          value: '${draft.travellers} · ${draft.cabin}',
          icon: Icons.group_rounded,
        ),
        _ReviewRow(
          label: 'Add-ons',
          value: draft.addons.isEmpty
              ? 'None'
              : draft.addons.map(_addonLabel).join(', '),
          icon: Icons.tune_rounded,
        ),
        const SizedBox(height: AppTokens.space3),
        PremiumCard(
          padding: const EdgeInsets.all(AppTokens.space4),
          gradient: LinearGradient(colors: [
            theme.colorScheme.primary.withValues(alpha: 0.20),
            theme.colorScheme.secondary.withValues(alpha: 0.04),
          ]),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTIMATED BUDGET',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    Text(
                      'USD \$${budget.toString()}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _addonLabel(String id) => switch (id) {
        'insurance' => 'Insurance',
        'lounge' => 'Lounge',
        'esim' => 'eSIM',
        'transfer' => 'Transfer',
        _ => id,
      };
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space2),
      child: PremiumCard(
        padding: const EdgeInsets.all(AppTokens.space3),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
              size: 18,
            ),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
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
