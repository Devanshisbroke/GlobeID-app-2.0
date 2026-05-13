import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/error_telemetry.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_chip.dart';
import '../../os2/primitives/os2_divider_rule.dart';
import '../../os2/primitives/os2_magnetic.dart';
import '../../os2/primitives/os2_slab.dart';
import '../../os2/primitives/os2_text.dart';
import '../../os2/primitives/os2_world_header.dart';

/// Debug-only error log viewer. Renders the rolling
/// `ErrorTelemetry` buffer so silent sub-tree crashes (caught by
/// `SafeBoundary` / `InlineErrorWidget`) and unhandled async errors
/// surface in one place for triage.
///
/// Reachable via `/debug/errors`. The route is gated behind
/// `kDebugMode || kProfileMode` so production builds redirect away.
class ErrorLogScreen extends StatelessWidget {
  const ErrorLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ValueListenableBuilder<int>(
          valueListenable: ErrorTelemetry.instance.revision,
          builder: (context, _, __) {
            final events = ErrorTelemetry.instance.events;
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Os2WorldHeader(
                    world: Os2World.pulse,
                    title: 'Error log',
                    subtitle: 'Recent runtime errors \u00b7 in-memory rolling buffer',
                    beacon: 'DEBUG',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Os2.space5),
                    child: Os2DividerRule(
                      eyebrow: 'BUFFER',
                      tone: Os2.signalCritical,
                      trailing: '${events.length} EVENT(S)',
                    ),
                  ),
                  const SizedBox(height: Os2.space3),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Os2.space4),
                    child: Row(
                      children: [
                        Os2Magnetic(
                          onTap: () {
                            ErrorTelemetry.instance.clear();
                          },
                          child: const Os2Chip(
                            label: 'CLEAR BUFFER',
                            icon: Icons.delete_sweep_rounded,
                            tone: Os2.signalCritical,
                            intensity: Os2ChipIntensity.solid,
                          ),
                        ),
                        const SizedBox(width: Os2.space3),
                        Os2Magnetic(
                          onTap: () => _copyAll(context, events),
                          child: const Os2Chip(
                            label: 'COPY ALL',
                            icon: Icons.copy_all_rounded,
                            tone: Os2.identityTone,
                            intensity: Os2ChipIntensity.ghost,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Os2.space4),
                  if (events.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Os2.space4),
                      child: Os2Slab(
                        tone: Os2.signalSettled,
                        tier: Os2SlabTier.floor1,
                        radius: Os2.rCard,
                        halo: Os2SlabHalo.none,
                        elevation: Os2SlabElevation.flat,
                        padding: const EdgeInsets.all(Os2.space5),
                        breath: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Os2Text.caption('BUFFER CLEAN',
                                color: Os2.signalSettled),
                            const SizedBox(height: Os2.space2),
                            Os2Text.body(
                              'No errors recorded since boot. The '
                              'telemetry sink is wired but quiet.',
                              color: Os2.inkMid,
                              size: 13,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Os2.space4),
                      child: Column(
                        children: [
                          for (final e in events) ...[
                            _ErrorTile(event: e),
                            const SizedBox(height: Os2.space3),
                          ],
                        ],
                      ),
                    ),
                  if (!(kDebugMode || kProfileMode))
                    Padding(
                      padding: const EdgeInsets.all(Os2.space4),
                      child: Os2Text.body(
                        'Telemetry capture is no-op in release builds.',
                        color: Os2.inkLow,
                        size: 12,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _copyAll(BuildContext context, List<ErrorEvent> events) async {
    if (events.isEmpty) return;
    final text = events
        .map((e) => '[${e.at.toIso8601String()}] '
            '(${e.kind} \u00b7 ${e.library})\n'
            '${e.summary}\n'
            '${e.stack}')
        .join('\n\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error log copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ErrorTile extends StatefulWidget {
  const _ErrorTile({required this.event});
  final ErrorEvent event;

  @override
  State<_ErrorTile> createState() => _ErrorTileState();
}

class _ErrorTileState extends State<_ErrorTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final tone = e.kind == 'async'
        ? Os2.signalCritical
        : Os2.signalAttention;
    return Os2Slab(
      tone: tone,
      tier: Os2SlabTier.floor1,
      radius: Os2.rCard,
      halo: Os2SlabHalo.corner,
      elevation: Os2SlabElevation.resting,
      padding: const EdgeInsets.all(Os2.space4),
      breath: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Os2Text.caption(
                '${e.kind.toUpperCase()} \u00b7 ${e.library.toUpperCase()}',
                color: tone,
              ),
              const Spacer(),
              Os2Text.caption(
                _shortTime(e.at),
                color: Os2.inkLow,
              ),
            ],
          ),
          const SizedBox(height: Os2.space2),
          Os2Text.body(
            e.summary,
            color: Os2.inkBright,
            size: 13,
            maxLines: _expanded ? 8 : 3,
          ),
          if (e.stack.isNotEmpty) ...[
            const SizedBox(height: Os2.space3),
            Os2Magnetic(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Os2Chip(
                label: _expanded ? 'HIDE STACK' : 'SHOW STACK',
                icon: _expanded
                    ? Icons.unfold_less_rounded
                    : Icons.unfold_more_rounded,
                tone: tone,
                intensity: Os2ChipIntensity.ghost,
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: Os2.space2),
              SelectableText(
                e.stack,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _shortTime(DateTime at) {
    final h = at.hour.toString().padLeft(2, '0');
    final m = at.minute.toString().padLeft(2, '0');
    final s = at.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
