import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import '../../motion/haptic_choreography.dart';
import '../../widgets/premium/premium.dart';

/// Outcome of a [PaymentConfirmSheet] interaction.
enum PaymentConfirmResult { confirmed, cancelled }

/// A magnetic, swipe-to-confirm payment sheet.
///
/// Anatomy:
///   • amount + recipient + method header
///   • split-flap amount with currency code
///   • magnetic swipe rail — drag the puck to the right to commit
///   • each rail tick fires `HapticPatterns.scrub`; the puck snapping
///     into the dock fires `HapticPatterns.paymentSwipe`, then
///     `HapticPatterns.confirm` after the success animation
class PaymentConfirmSheet extends StatefulWidget {
  const PaymentConfirmSheet({
    super.key,
    required this.amount,
    required this.currency,
    required this.recipient,
    this.methodLabel = 'Default wallet',
    this.note,
    this.tone,
  });

  final double amount;
  final String currency;
  final String recipient;
  final String methodLabel;
  final String? note;
  final Color? tone;

  static Future<PaymentConfirmResult?> show(
    BuildContext context, {
    required double amount,
    required String currency,
    required String recipient,
    String methodLabel = 'Default wallet',
    String? note,
    Color? tone,
  }) {
    return showModalBottomSheet<PaymentConfirmResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentConfirmSheet(
        amount: amount,
        currency: currency,
        recipient: recipient,
        methodLabel: methodLabel,
        note: note,
        tone: tone,
      ),
    );
  }

  @override
  State<PaymentConfirmSheet> createState() => _PaymentConfirmSheetState();
}

class _PaymentConfirmSheetState extends State<PaymentConfirmSheet>
    with TickerProviderStateMixin {
  double _slide = 0;
  bool _committing = false;
  bool _done = false;

  void _onDragUpdate(DragUpdateDetails d, double maxWidth) {
    if (_committing || _done) return;
    final next = (_slide + d.delta.dx / maxWidth).clamp(0.0, 1.0);
    if ((next * 10).round() != (_slide * 10).round()) {
      HapticPatterns.scrub.play();
    }
    setState(() => _slide = next);
  }

  Future<void> _onDragEnd(double maxWidth) async {
    if (_committing || _done) return;
    if (_slide >= 0.92) {
      setState(() {
        _slide = 1.0;
        _committing = true;
      });
      HapticPatterns.paymentSwipe.play();
      await Future.delayed(const Duration(milliseconds: 320));
      HapticPatterns.confirm.play();
      setState(() => _done = true);
      await Future.delayed(const Duration(milliseconds: 540));
      if (mounted) {
        Navigator.of(context).pop(PaymentConfirmResult.confirmed);
      }
    } else {
      setState(() => _slide = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = widget.tone ?? theme.colorScheme.primary;
    final mq = MediaQuery.of(context);
    final amountText = widget.amount.toStringAsFixed(2);

    return Padding(
      padding: EdgeInsets.only(
        bottom: mq.viewInsets.bottom + AppTokens.space5,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
          child: ContextualSurface(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space5,
              AppTokens.space5,
              AppTokens.space5,
              AppTokens.space4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusFull),
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.space4),
                Text(
                  'Confirm payment',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: AppTokens.space1),
                Text(
                  'To ${widget.recipient}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: AppTokens.space5),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: 8, right: AppTokens.space2),
                        child: Text(widget.currency,
                            style: AirportFontStack.iata(context, size: 18)),
                      ),
                      DepartureBoardText(
                        text: amountText.padLeft(7),
                        charWidth: 28,
                        style: AirportFontStack.board(context, size: 38),
                        tone: tone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.space2),
                Center(
                  child: Text(
                    widget.methodLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (widget.note != null) ...[
                  const SizedBox(height: AppTokens.space3),
                  Center(
                    child: Text(
                      widget.note!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppTokens.space6),
                LayoutBuilder(
                  builder: (_, c) {
                    final w = c.maxWidth;
                    return _SwipeRail(
                      slide: _slide,
                      done: _done,
                      committing: _committing,
                      tone: tone,
                      width: w,
                      onUpdate: (d) => _onDragUpdate(d, w),
                      onEnd: () => _onDragEnd(w),
                    );
                  },
                ),
                const SizedBox(height: AppTokens.space2),
                Center(
                  child: TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(PaymentConfirmResult.cancelled),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeRail extends StatelessWidget {
  const _SwipeRail({
    required this.slide,
    required this.done,
    required this.committing,
    required this.tone,
    required this.width,
    required this.onUpdate,
    required this.onEnd,
  });
  final double slide;
  final bool done;
  final bool committing;
  final Color tone;
  final double width;
  final ValueChanged<DragUpdateDetails> onUpdate;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final puckSize = 56.0;
    final puckLeft = (width - puckSize) * slide;
    final railHeight = 64.0;

    return Stack(
      children: [
        Container(
          width: width,
          height: railHeight,
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          ),
          alignment: Alignment.center,
          child: Text(
            done
                ? 'Payment locked'
                : committing
                    ? 'Confirming…'
                    : 'Slide to pay',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        AnimatedPositioned(
          duration: AppTokens.durationXs,
          curve: AppTokens.easeOutSoft,
          left: 4 + puckLeft,
          top: 4,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: onUpdate,
            onHorizontalDragEnd: (_) => onEnd(),
            child: Container(
              width: puckSize - 8,
              height: railHeight - 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tone,
                    Color.lerp(tone, Colors.white, 0.35)!,
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(AppTokens.radiusFull),
                boxShadow: [
                  BoxShadow(
                    color: tone.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                done
                    ? Icons.lock_rounded
                    : committing
                        ? Icons.bolt_rounded
                        : Icons.east_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
