import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/models/wallet_models.dart';
import '../../motion/haptic_choreography.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium/premium.dart';
import '../wallet/wallet_provider.dart';

/// Premium multi-currency conversion — pours liquid from the source
/// currency into the target. Drag the dial to set the target amount,
/// release to commit. Each tick of the dial fires a `pourTick` haptic.
class MultiCurrencyPourScreen extends ConsumerStatefulWidget {
  const MultiCurrencyPourScreen({super.key});

  @override
  ConsumerState<MultiCurrencyPourScreen> createState() =>
      _MultiCurrencyPourScreenState();
}

class _MultiCurrencyPourScreenState
    extends ConsumerState<MultiCurrencyPourScreen> {
  String? _from;
  String? _to;
  double _amount = 100;
  bool _pouring = false;
  Timer? _pourTimer;
  double _pourProgress = 0;

  @override
  void dispose() {
    _pourTimer?.cancel();
    super.dispose();
  }

  void _pickFrom(WalletBalance b) => setState(() => _from = b.currency);
  void _pickTo(WalletBalance b) => setState(() => _to = b.currency);

  Future<void> _commit() async {
    if (_from == null || _to == null) return;
    setState(() {
      _pouring = true;
      _pourProgress = 0;
    });
    HapticPatterns.pressureBegin.play();
    _pourTimer?.cancel();
    _pourTimer = Timer.periodic(const Duration(milliseconds: 40), (t) {
      setState(() {
        _pourProgress = (_pourProgress + 0.014).clamp(0.0, 1.0);
      });
      if (t.tick % 6 == 0) HapticPatterns.pourTick.play();
      if (_pourProgress >= 1.0) {
        t.cancel();
        HapticPatterns.currencyPourEnd.play();
        Future.delayed(const Duration(milliseconds: 320), () {
          if (mounted) setState(() => _pouring = false);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final theme = Theme.of(context);
    final balances = wallet.balances;
    _from ??= wallet.defaultCurrency;
    _to ??= balances
        .firstWhere(
          (b) => b.currency != _from,
          orElse: () => balances.first,
        )
        .currency;
    final source = balances.firstWhere(
      (b) => b.currency == _from,
      orElse: () => balances.first,
    );
    final target = balances.firstWhere(
      (b) => b.currency == _to,
      orElse: () => balances.last,
    );
    return PageScaffold(
      title: 'Convert',
      subtitle: 'Pour from one currency to another',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _Header(
            from: source,
            to: target,
            amount: _amount,
          ),
          const SizedBox(height: AppTokens.space5),
          _PourDeck(
            progress: _pourProgress,
            tone: theme.colorScheme.primary,
            sourceLabel: source.currency,
            targetLabel: target.currency,
            amount: _amount,
          ),
          const SizedBox(height: AppTokens.space5),
          _AmountDial(
            amount: _amount,
            onChanged: (v) => setState(() => _amount = v),
          ),
          const SizedBox(height: AppTokens.space5),
          ContextualSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('From', style: theme.textTheme.labelMedium),
                const SizedBox(height: AppTokens.space2),
                _Picker(
                  balances: balances,
                  selected: _from!,
                  onPick: _pickFrom,
                ),
                const Divider(height: AppTokens.space7),
                Text('To', style: theme.textTheme.labelMedium),
                const SizedBox(height: AppTokens.space2),
                _Picker(
                  balances: balances,
                  selected: _to!,
                  onPick: _pickTo,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space5),
          MagneticButton(
            label: _pouring ? 'Pouring…' : 'Convert $_amount $_from to $_to',
            icon:
                _pouring ? Icons.water_drop_rounded : Icons.swap_horiz_rounded,
            onPressed: _pouring ? null : _commit,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.from,
    required this.to,
    required this.amount,
  });
  final WalletBalance from;
  final WalletBalance to;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return ContextualSurface(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space5,
        AppTokens.space4,
        AppTokens.space5,
        AppTokens.space4,
      ),
      child: Row(
        children: [
          Expanded(
            child: _CurrencySummary(
              code: from.currency,
              amount: from.amount,
              label: 'Source',
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTokens.space3),
            child: Icon(Icons.east_rounded),
          ),
          Expanded(
            child: _CurrencySummary(
              code: to.currency,
              amount: to.amount,
              label: 'Target',
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencySummary extends StatelessWidget {
  const _CurrencySummary({
    required this.code,
    required this.amount,
    required this.label,
  });
  final String code;
  final double amount;
  final String label;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
            )),
        const SizedBox(height: AppTokens.space1),
        Text(code, style: AirportFontStack.iata(context, size: 20)),
        const SizedBox(height: AppTokens.space1),
        Text(amount.toStringAsFixed(2),
            style: theme.textTheme.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w700,
            )),
      ],
    );
  }
}

class _PourDeck extends StatelessWidget {
  const _PourDeck({
    required this.progress,
    required this.tone,
    required this.sourceLabel,
    required this.targetLabel,
    required this.amount,
  });
  final double progress;
  final Color tone;
  final String sourceLabel;
  final String targetLabel;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ContextualSurface(
      padding: const EdgeInsets.all(AppTokens.space4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: LiquidWaveSurface(
                  progress: 1 - progress,
                  tone: tone,
                  height: 110,
                  amplitude: 4,
                  child: Center(
                    child: Text(
                      sourceLabel,
                      style: AirportFontStack.iata(context, size: 22),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space3),
              const Icon(Icons.water_drop_rounded, size: 28),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: LiquidWaveSurface(
                  progress: progress,
                  tone: theme.colorScheme.secondary,
                  height: 110,
                  amplitude: 4,
                  child: Center(
                    child: Text(
                      targetLabel,
                      style: AirportFontStack.iata(context, size: 22),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space3),
          Text(
            progress >= 1.0
                ? 'Done — \$${amount.toStringAsFixed(2)} converted'
                : 'Pouring ${(progress * 100).round()}%',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountDial extends StatefulWidget {
  const _AmountDial({required this.amount, required this.onChanged});
  final double amount;
  final ValueChanged<double> onChanged;
  @override
  State<_AmountDial> createState() => _AmountDialState();
}

class _AmountDialState extends State<_AmountDial> {
  double _last = 0;
  void _onChange(double v) {
    final next = double.parse(v.toStringAsFixed(2));
    if ((next - _last).abs() >= 5) {
      HapticPatterns.scrub.play();
      _last = next;
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ContextualSurface(
      padding: const EdgeInsets.all(AppTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amount',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: AppTokens.space2),
          Center(
            child: DepartureBoardText(
              text: widget.amount.toStringAsFixed(0).padLeft(4),
              charWidth: 28,
              style: AirportFontStack.board(context, size: 36),
              tone: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          Slider(
            value: widget.amount.clamp(0, 5000),
            min: 0,
            max: 5000,
            divisions: 100,
            label: widget.amount.toStringAsFixed(0),
            onChanged: _onChange,
          ),
        ],
      ),
    );
  }
}

class _Picker extends StatelessWidget {
  const _Picker({
    required this.balances,
    required this.selected,
    required this.onPick,
  });
  final List<WalletBalance> balances;
  final String selected;
  final void Function(WalletBalance) onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: balances.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTokens.space2),
        itemBuilder: (_, i) {
          final b = balances[i];
          final on = b.currency == selected;
          return MagneticPressable(
            onTap: () => onPick(b),
            child: AnimatedContainer(
              duration: AppTokens.durationSm,
              curve: AppTokens.easeOutSoft,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space4,
                vertical: AppTokens.space3,
              ),
              decoration: BoxDecoration(
                gradient: on
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      )
                    : null,
                color: on ? null : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppTokens.radiusXl),
                border: Border.all(
                  color: Colors.white.withValues(alpha: on ? 0.3 : 0.08),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.currency,
                      style: AirportFontStack.iata(context, size: 16)
                          .copyWith(color: on ? Colors.white : null)),
                  const SizedBox(height: 2),
                  Text(b.amount.toStringAsFixed(2),
                      style: TextStyle(
                        color: on
                            ? Colors.white.withValues(alpha: 0.8)
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
