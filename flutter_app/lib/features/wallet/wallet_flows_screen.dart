import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/cinematic_hero.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/section_header.dart';
import '../payments/payment_confirm_sheet.dart';

/// Wallet "flow" screens — Send, Receive, Scan-to-pay, Exchange.
///
/// All four are derived from a single shared scaffold so the chrome,
/// header band, keypad treatment, and confirmation animations are
/// consistent. Each flow is opened from the WalletScreen action bar
/// (or the router) and persists local input state.

/// The four flows we support.
enum WalletFlow { send, receive, scanPay, exchange }

class WalletFlowScreen extends ConsumerStatefulWidget {
  const WalletFlowScreen({super.key, required this.flow});
  final WalletFlow flow;

  @override
  ConsumerState<WalletFlowScreen> createState() => _WalletFlowScreenState();
}

class _WalletFlowScreenState extends ConsumerState<WalletFlowScreen> {
  String _amount = '0';
  String _from = 'USD';
  String _to = 'JPY';
  String _recipient = '';

  void _digit(String d) {
    HapticFeedback.selectionClick();
    setState(() {
      if (d == '⌫') {
        if (_amount.length <= 1) {
          _amount = '0';
        } else {
          _amount = _amount.substring(0, _amount.length - 1);
        }
        return;
      }
      if (d == '.' && _amount.contains('.')) return;
      if (_amount == '0' && d != '.') {
        _amount = d;
      } else {
        _amount = '$_amount$d';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flow = widget.flow;
    final tone = _toneFor(flow);
    return PageScaffold(
      title: _titleFor(flow),
      subtitle: _subtitleFor(flow),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: AnimatedAppearance(
              child: CinematicHero(
                eyebrow: 'WALLET · ${_eyebrowFor(flow).toUpperCase()}',
                title: _formatAmount(),
                subtitle: _subtitleFor(flow),
                icon: _iconFor(flow),
                tone: tone,
                badges: _badgesFor(flow),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space5)),
          if (flow == WalletFlow.send) ...[
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Recipient',
                subtitle: 'GlobeID handle, email, or phone',
              ),
            ),
            SliverToBoxAdapter(
              child: PremiumCard(
                padding: const EdgeInsets.all(AppTokens.space3),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '@aiko · sushi@saito.tokyo · +81…',
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.alternate_email_rounded,
                        color: tone, size: 18),
                  ),
                  onChanged: (v) => setState(() => _recipient = v),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space3)),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  itemCount: _frequents.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppTokens.space2),
                  itemBuilder: (_, i) => _RecipientChip(
                    name: _frequents[i].$1,
                    flag: _frequents[i].$2,
                    tone: tone,
                    selected: _recipient == _frequents[i].$1,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _recipient = _frequents[i].$1);
                    },
                  ),
                ),
              ),
            ),
          ],
          if (flow == WalletFlow.exchange) ...[
            const SliverToBoxAdapter(
              child: SectionHeader(
                  title: 'Convert', subtitle: 'Live rate · 0.4% spread'),
            ),
            SliverToBoxAdapter(
              child: _CurrencyPair(
                tone: tone,
                from: _from,
                to: _to,
                onSwap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    final t = _from;
                    _from = _to;
                    _to = t;
                  });
                },
              ),
            ),
          ],
          if (flow == WalletFlow.receive) ...[
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Show this code',
                subtitle: 'Anyone can scan with their wallet',
              ),
            ),
            SliverToBoxAdapter(
              child: PremiumCard(
                padding: const EdgeInsets.all(AppTokens.space5),
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTokens.radiusXl),
                        child: CustomPaint(
                          painter:
                              _QrPainter(tone: tone, seed: 'globeid:devansh'),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTokens.space3),
                    Text('@devansh.globeid',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: tone,
                          letterSpacing: 0.5,
                        )),
                  ],
                ),
              ),
            ),
          ],
          if (flow == WalletFlow.scanPay) ...[
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Camera scan',
                subtitle: 'Hold a QR to charge',
              ),
            ),
            SliverToBoxAdapter(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.radius2xl),
                child: SizedBox(
                  height: 240,
                  child: CustomPaint(
                    painter: _ScanFramePainter(tone: tone),
                  ),
                ),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space5)),
          if (flow != WalletFlow.receive) ...[
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Amount',
                subtitle: 'Tap to enter',
              ),
            ),
            SliverToBoxAdapter(
              child: _Keypad(
                tone: tone,
                onDigit: _digit,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space5)),
          ],
          SliverToBoxAdapter(
            child: CinematicButton(
              label: _ctaFor(flow),
              icon: _iconFor(flow),
              gradient: LinearGradient(
                colors: [tone, tone.withValues(alpha: 0.55)],
              ),
              onPressed: () async {
                HapticFeedback.heavyImpact();
                if (flow == WalletFlow.send || flow == WalletFlow.scanPay) {
                  final amount = double.tryParse(_amount) ?? 0;
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  final result = await PaymentConfirmSheet.show(
                    context,
                    amount: amount,
                    currency: 'USD',
                    recipient: _recipient.isNotEmpty
                        ? _recipient
                        : (flow == WalletFlow.scanPay
                            ? 'Scanned merchant'
                            : 'Recipient'),
                    methodLabel: 'Default wallet',
                    tone: tone,
                  );
                  if (!mounted) return;
                  if (result == PaymentConfirmResult.confirmed) {
                    messenger.showSnackBar(
                      SnackBar(
                        backgroundColor: tone,
                        content: Text(_confirmFor(flow)),
                      ),
                    );
                    navigator.maybePop();
                  }
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: tone,
                    content: Text(_confirmFor(flow)),
                  ),
                );
                Navigator.of(context).maybePop();
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppTokens.space9)),
        ],
      ),
    );
  }

  static const _frequents = <(String, String)>[
    ('@aiko', '🇯🇵'),
    ('@marco', '🇮🇹'),
    ('@priya', '🇮🇳'),
    ('@james', '🇬🇧'),
    ('@li', '🇨🇳'),
    ('@ana', '🇧🇷'),
  ];

  String _formatAmount() {
    final base = double.tryParse(_amount) ?? 0;
    final sym = switch (widget.flow) {
      WalletFlow.exchange => _from,
      WalletFlow.send => 'USD',
      WalletFlow.scanPay => 'USD',
      WalletFlow.receive => 'USD',
    };
    if (widget.flow == WalletFlow.exchange) {
      const rate = 156.42; // demo USD→JPY
      final converted = (_from == 'USD' ? base * rate : base / rate);
      return '$_amount $_from   →   ${converted.toStringAsFixed(0)} $_to';
    }
    return '$_amount $sym';
  }

  String _titleFor(WalletFlow f) => switch (f) {
        WalletFlow.send => 'Send',
        WalletFlow.receive => 'Receive',
        WalletFlow.scanPay => 'Scan to pay',
        WalletFlow.exchange => 'Exchange',
      };

  String _subtitleFor(WalletFlow f) => switch (f) {
        WalletFlow.send => 'Instant · across 32 currencies',
        WalletFlow.receive => 'Show your code · auto-syncs to history',
        WalletFlow.scanPay => 'Tap-and-go for kiosks, taxis, food',
        WalletFlow.exchange => 'Multi-currency conversion',
      };

  String _eyebrowFor(WalletFlow f) => switch (f) {
        WalletFlow.send => 'send',
        WalletFlow.receive => 'receive',
        WalletFlow.scanPay => 'scan',
        WalletFlow.exchange => 'exchange',
      };

  IconData _iconFor(WalletFlow f) => switch (f) {
        WalletFlow.send => Icons.arrow_upward_rounded,
        WalletFlow.receive => Icons.qr_code_2_rounded,
        WalletFlow.scanPay => Icons.qr_code_scanner_rounded,
        WalletFlow.exchange => Icons.currency_exchange_rounded,
      };

  Color _toneFor(WalletFlow f) => switch (f) {
        WalletFlow.send => const Color(0xFF0EA5E9),
        WalletFlow.receive => const Color(0xFF10B981),
        WalletFlow.scanPay => const Color(0xFF7E22CE),
        WalletFlow.exchange => const Color(0xFFD97706),
      };

  String _ctaFor(WalletFlow f) => switch (f) {
        WalletFlow.send =>
          'Send · ${_recipient.isEmpty ? 'select recipient' : _recipient}',
        WalletFlow.receive => 'Share my code',
        WalletFlow.scanPay => 'Confirm scan',
        WalletFlow.exchange => 'Convert $_amount $_from',
      };

  String _confirmFor(WalletFlow f) => switch (f) {
        WalletFlow.send =>
          'Sent \$$_amount${_recipient.isEmpty ? '' : ' to $_recipient'}',
        WalletFlow.receive => 'Receipt link copied',
        WalletFlow.scanPay => 'Charged \$$_amount · receipt saved',
        WalletFlow.exchange => 'Converted $_amount $_from to $_to',
      };

  List<HeroBadge> _badgesFor(WalletFlow f) {
    switch (f) {
      case WalletFlow.send:
        return const [
          HeroBadge(label: 'Instant', icon: Icons.bolt_rounded),
          HeroBadge(label: '0% fee', icon: Icons.local_offer_rounded),
        ];
      case WalletFlow.receive:
        return const [
          HeroBadge(label: 'Multi-currency', icon: Icons.public_rounded),
          HeroBadge(label: 'Auto-FX', icon: Icons.swap_horiz_rounded),
        ];
      case WalletFlow.scanPay:
        return const [
          HeroBadge(label: 'NFC', icon: Icons.nfc_rounded),
          HeroBadge(label: 'QR', icon: Icons.qr_code_rounded),
        ];
      case WalletFlow.exchange:
        return const [
          HeroBadge(label: 'Live rate', icon: Icons.show_chart_rounded),
          HeroBadge(label: '0.4% spread', icon: Icons.trending_down_rounded),
        ];
    }
  }
}

class _RecipientChip extends StatelessWidget {
  const _RecipientChip({
    required this.name,
    required this.flag,
    required this.tone,
    required this.selected,
    required this.onTap,
  });
  final String name;
  final String flag;
  final Color tone;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.95,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationSm,
        width: 88,
        padding: const EdgeInsets.all(AppTokens.space2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius2xl),
          color: selected
              ? tone.withValues(alpha: 0.20)
              : theme.colorScheme.surface.withValues(alpha: 0.55),
          border: Border.all(
            color: selected
                ? tone.withValues(alpha: 0.55)
                : theme.colorScheme.onSurface.withValues(alpha: 0.10),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: tone.withValues(alpha: 0.22),
              child: Text(flag, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 4),
            Text(name,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? tone
                      : theme.colorScheme.onSurface.withValues(alpha: 0.78),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _CurrencyPair extends StatelessWidget {
  const _CurrencyPair({
    required this.tone,
    required this.from,
    required this.to,
    required this.onSwap,
  });
  final Color tone;
  final String from;
  final String to;
  final VoidCallback onSwap;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(AppTokens.space3),
      child: Row(
        children: [
          Expanded(
            child: _CurrencyTile(label: 'FROM', code: from, tone: tone),
          ),
          Pressable(
            scale: 0.9,
            onTap: onSwap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tone.withValues(alpha: 0.18),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.swap_horiz_rounded, color: tone),
            ),
          ),
          Expanded(
            child: _CurrencyTile(label: 'TO', code: to, tone: tone),
          ),
        ],
      ),
    );
  }
}

class _CurrencyTile extends StatelessWidget {
  const _CurrencyTile({
    required this.label,
    required this.code,
    required this.tone,
  });
  final String label;
  final String code;
  final Color tone;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              fontSize: 10,
            )),
        const SizedBox(height: 2),
        Text(code,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: tone,
            )),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.tone, required this.onDigit});
  final Color tone;
  final ValueChanged<String> onDigit;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                for (final d in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _KeypadKey(
                        label: d,
                        tone: tone,
                        onTap: () => onDigit(d),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({
    required this.label,
    required this.tone,
    required this.onTap,
  });
  final String label;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDelete = label == '⌫';
    return Pressable(
      scale: 0.92,
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius2xl),
          color: theme.colorScheme.surface.withValues(alpha: 0.55),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
          ),
        ),
        child: isDelete
            ? Icon(Icons.backspace_rounded, color: tone, size: 18)
            : Text(label,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  const _QrPainter({required this.tone, required this.seed});
  final Color tone;
  final String seed;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bg);

    final cellSize = size.width / 21;
    final fg = Paint()..color = const Color(0xFF0F172A);
    var h = 0;
    for (final c in seed.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    final rng = math.Random(h);
    for (var x = 0; x < 21; x++) {
      for (var y = 0; y < 21; y++) {
        // Finder patterns at corners
        final inFinder =
            (x < 7 && y < 7) || (x > 13 && y < 7) || (x < 7 && y > 13);
        if (inFinder) {
          final isOuter = x == 0 ||
              x == 6 ||
              y == 0 ||
              y == 6 ||
              (x == 14 || x == 20 || y == 14) ||
              (y == 0 && x > 13);
          final isInner = (x >= 2 && x <= 4 && y >= 2 && y <= 4) ||
              (x >= 16 && x <= 18 && y >= 2 && y <= 4) ||
              (x >= 2 && x <= 4 && y >= 16 && y <= 18);
          if (isOuter || isInner) {
            canvas.drawRect(
              Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
              fg,
            );
          }
          continue;
        }
        if (rng.nextDouble() < 0.48) {
          canvas.drawRect(
            Rect.fromLTWH(x * cellSize, y * cellSize, cellSize, cellSize),
            fg,
          );
        }
      }
    }

    // Brand mark
    final center = Offset(
        size.width / 2 - cellSize * 1.5, size.height / 2 - cellSize * 1.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(center & Size(cellSize * 3, cellSize * 3),
          Radius.circular(cellSize * 0.6)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          (center + Offset(cellSize * 0.5, cellSize * 0.5)) &
              Size(cellSize * 2, cellSize * 2),
          Radius.circular(cellSize * 0.4)),
      Paint()..color = tone,
    );
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) =>
      old.seed != seed || old.tone != tone;
}

class _ScanFramePainter extends CustomPainter {
  const _ScanFramePainter({required this.tone});
  final Color tone;
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF0F172A),
          const Color(0xFF1E293B),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Frame
    final f = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = tone;
    final box = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 168,
        height: 168);
    final corner = 24.0;
    void drawCorner(Offset p, Offset dx, Offset dy) {
      canvas.drawLine(p, p + dx, f);
      canvas.drawLine(p, p + dy, f);
    }

    drawCorner(box.topLeft, Offset(corner, 0), Offset(0, corner));
    drawCorner(box.topRight, Offset(-corner, 0), Offset(0, corner));
    drawCorner(box.bottomLeft, Offset(corner, 0), Offset(0, -corner));
    drawCorner(box.bottomRight, Offset(-corner, 0), Offset(0, -corner));

    // Scan line
    final scanY = size.height / 2 + math.sin(0) * 8;
    final scan = Paint()
      ..color = tone.withValues(alpha: 0.55)
      ..strokeWidth = 1.4;
    canvas.drawLine(
        Offset(box.left + 4, scanY), Offset(box.right - 4, scanY), scan);
  }

  @override
  bool shouldRepaint(covariant _ScanFramePainter old) => false;
}
