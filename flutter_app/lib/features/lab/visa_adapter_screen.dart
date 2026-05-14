import 'package:flutter/material.dart';

import '../../data/visa/demo_visa_adapter.dart';
import '../../data/visa/passport_index_visa_adapter.dart';
import '../../data/visa/visa_models.dart';
import '../../data/visa/visa_service.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';

class VisaAdapterScreen extends StatefulWidget {
  const VisaAdapterScreen({super.key});
  @override
  State<VisaAdapterScreen> createState() => _VisaAdapterScreenState();
}

class _VisaAdapterScreenState extends State<VisaAdapterScreen> {
  bool _live = false;
  bool _loading = false;
  String? _error;
  List<VisaRule> _rules = const [];
  VisaService? _service;
  String _passport = 'IN';

  static const _passports = ['IN', 'US', 'DE'];

  @override
  void initState() {
    super.initState();
    _rebuildService();
    _load();
  }

  void _rebuildService() {
    _service = VisaService(
      adapter: _live ? PassportIndexVisaAdapter() : DemoVisaAdapter(),
      fallback: _live ? DemoVisaAdapter() : null,
    );
  }

  Future<void> _load() async {
    final svc = _service;
    if (svc == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rules = await svc.rulesFor(_passport);
      if (!mounted) return;
      setState(() {
        _rules = rules;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Visa adapter',
      subtitle: _live
          ? 'Live · PassportIndex matrix'
          : 'Demo · PassportIndex 2024 snapshot',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          _SourceCard(
            live: _live,
            loading: _loading,
            passport: _passport,
            passports: _passports,
            onSourceToggle: (v) {
              if (_live == v) return;
              setState(() {
                _live = v;
                _rules = const [];
              });
              _rebuildService();
              _load();
            },
            onPassportChange: (p) {
              if (_passport == p) return;
              setState(() => _passport = p);
              _load();
            },
            onRefresh: _loading ? null : _load,
          ),
          const SizedBox(height: Os2.space4),
          if (_error != null) ...[
            _ErrorCard(message: _error!),
            const SizedBox(height: Os2.space4),
          ],
          ..._rules.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: Os2.space3),
                child: _RuleCard(rule: r),
              )),
          const SizedBox(height: Os2.space4),
          const _IntegrationCard(),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.live,
    required this.loading,
    required this.passport,
    required this.passports,
    required this.onSourceToggle,
    required this.onPassportChange,
    required this.onRefresh,
  });
  final bool live;
  final bool loading;
  final String passport;
  final List<String> passports;
  final ValueChanged<bool> onSourceToggle;
  final ValueChanged<String> onPassportChange;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: Os2.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(
            'SOURCE · PASSPORT',
            color: Os2.goldDeep,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          Row(
            children: [
              _Chip(
                label: 'DEMO',
                active: !live,
                onTap: () => onSourceToggle(false),
              ),
              const SizedBox(width: 8),
              _Chip(
                label: 'LIVE',
                active: live,
                onTap: () => onSourceToggle(true),
              ),
              const Spacer(),
              Pressable(
                onTap: onRefresh,
                semanticLabel: 'Refresh visa rules',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: Os2.foilGoldHero,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (loading)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.6,
                            color: Os2.canvas,
                          ),
                        )
                      else
                        const Icon(
                          Icons.refresh_rounded,
                          color: Os2.canvas,
                          size: 14,
                        ),
                      const SizedBox(width: 6),
                      Os2Text.monoCap(
                        'REFRESH',
                        color: Os2.canvas,
                        size: Os2.textTiny,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Os2.space3),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in passports)
                _Chip(
                  label: p,
                  active: p == passport,
                  onTap: () => onPassportChange(p),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Os2.goldDeep.withValues(alpha: 0.18) : null,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? Os2.goldDeep.withValues(alpha: 0.62)
                : Os2.hairline,
          ),
        ),
        child: Os2Text.monoCap(
          label,
          color: active ? Os2.goldDeep : Os2.inkLow,
          size: Os2.textTiny,
        ),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule});
  final VisaRule rule;
  @override
  Widget build(BuildContext context) {
    final tone = Color(rule.category.tone);
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: Os2.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Os2Text.monoCap(
                rule.corridor.handle,
                color: Os2.inkBright,
                size: Os2.textTiny,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tone.withValues(alpha: 0.62)),
                ),
                child: Os2Text.monoCap(
                  rule.category.handle,
                  color: tone,
                  size: Os2.textTiny,
                ),
              ),
            ],
          ),
          if (rule.maxStayDays != null) ...[
            const SizedBox(height: Os2.space2),
            Os2Text.monoCap(
              'MAX · STAY · ${rule.maxStayDays}d',
              color: Os2.inkMid,
              size: Os2.textTiny,
            ),
          ],
          if (rule.notes != null) ...[
            const SizedBox(height: Os2.space2),
            Os2Text.body(
              rule.notes!,
              color: Os2.inkMid,
              size: Os2.textSm,
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A0F0F),
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: const Color(0xFFFF6A6A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(
            'FETCH · FAILED',
            color: const Color(0xFFFF8A8A),
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          Os2Text.body(message, color: Os2.inkBright, size: Os2.textSm),
        ],
      ),
    );
  }
}

class _IntegrationCard extends StatelessWidget {
  const _IntegrationCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Os2.space4),
      decoration: BoxDecoration(
        color: Os2.floor1,
        borderRadius: BorderRadius.circular(Os2.rCard),
        border: Border.all(color: Os2.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Os2Text.monoCap(
            'CONTRACT',
            color: Os2.goldDeep,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          Os2Text.body(
            'Every visa source in GlobeID implements VisaAdapter — `Future<VisaRule> rule(VisaCorridor)` and `Future<List<VisaRule>> rulesFor(String passport)`. VisaService caches per corridor, single-flights concurrent calls, and falls back to demo when the upstream feed fails.',
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
          const SizedBox(height: Os2.space3),
          Os2Text.body(
            'PassportIndex — open-source visa matrix on GitHub. Fetched once per session, parsed into an ISO→ISO map. Demo — a curated 2024 snapshot anchored to IN / US / DE passports for offline-first rendering.',
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
        ],
      ),
    );
  }
}
