import 'package:flutter/material.dart';

import '../../data/telemetry/buffer_telemetry_sink.dart';
import '../../data/telemetry/console_telemetry_sink.dart';
import '../../data/telemetry/sentry_telemetry_sink.dart';
import '../../data/telemetry/telemetry_event.dart';
import '../../data/telemetry/telemetry_service.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';

class TelemetrySinkScreen extends StatefulWidget {
  const TelemetrySinkScreen({super.key});
  @override
  State<TelemetrySinkScreen> createState() => _TelemetrySinkScreenState();
}

class _TelemetrySinkScreenState extends State<TelemetrySinkScreen> {
  late final BufferTelemetrySink _buffer;
  late final ConsoleTelemetrySink _console;
  late final SentryTelemetrySink _sentry;
  late final TelemetryService _service;

  @override
  void initState() {
    super.initState();
    _buffer = BufferTelemetrySink(capacity: 32);
    _console = ConsoleTelemetrySink();
    _sentry = SentryTelemetrySink();
    _service = TelemetryService(sinks: [_buffer, _console, _sentry]);
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  Future<void> _emit(TelemetryLevel level) async {
    await _service.emit(TelemetryEvent(
      kind: 'lab.sample',
      message: switch (level) {
        TelemetryLevel.debug => 'Cold mount complete · 412ms',
        TelemetryLevel.info => 'User opened Wallet · 2 credentials',
        TelemetryLevel.warning => 'Visa expires in 11 days · IN→AE',
        TelemetryLevel.error => 'Failed to load FX snapshot',
        TelemetryLevel.fatal => 'Crash on credential decode',
      },
      level: level,
      timestamp: DateTime.now(),
      attributes: {'source': 'lab', 'user_tier': 'staff'},
      fingerprint: 'lab.${level.handle}',
      library: 'lab.telemetry',
      stack: level.index >= TelemetryLevel.error.index
          ? 'lab/telemetry_sink_screen.dart:42:7\nlab/telemetry_sink_screen.dart:38:5'
          : '',
    ));
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Telemetry sink',
      subtitle: 'Buffer · Console · Sentry',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Os2.space5,
          Os2.space2,
          Os2.space5,
          Os2.space7,
        ),
        children: [
          _SinkRosterCard(service: _service),
          const SizedBox(height: Os2.space4),
          _EmitCard(onEmit: _emit),
          const SizedBox(height: Os2.space4),
          _BufferCard(buffer: _buffer),
          const SizedBox(height: Os2.space4),
          const _IntegrationCard(),
        ],
      ),
    );
  }
}

class _SinkRosterCard extends StatelessWidget {
  const _SinkRosterCard({required this.service});
  final TelemetryService service;
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
            'SINKS · ROSTER',
            color: Os2.goldDeep,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          for (final s in service.sinks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: s.enabled
                          ? const Color(0xFF6CE0A8)
                          : Os2.inkLow.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Os2Text.monoCap(
                    s.name.toUpperCase(),
                    color: Os2.inkBright,
                    size: Os2.textTiny,
                  ),
                  const Spacer(),
                  Os2Text.monoCap(
                    s.enabled ? 'ACTIVE' : 'IDLE',
                    color: s.enabled ? const Color(0xFF6CE0A8) : Os2.inkLow,
                    size: Os2.textTiny,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmitCard extends StatelessWidget {
  const _EmitCard({required this.onEmit});
  final Future<void> Function(TelemetryLevel) onEmit;
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
            'EMIT · SAMPLE',
            color: Os2.goldDeep,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final l in TelemetryLevel.values)
                Pressable(
                  onTap: () => onEmit(l),
                  semanticLabel: 'Emit ${l.handle}',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Color(l.tone).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Color(l.tone).withValues(alpha: 0.62),
                      ),
                    ),
                    child: Os2Text.monoCap(
                      l.handle,
                      color: Color(l.tone),
                      size: Os2.textTiny,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BufferCard extends StatelessWidget {
  const _BufferCard({required this.buffer});
  final BufferTelemetrySink buffer;
  @override
  Widget build(BuildContext context) {
    final events = buffer.events;
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
            'BUFFER · LAST ${events.length}',
            color: Os2.goldDeep,
            size: Os2.textTiny,
          ),
          const SizedBox(height: Os2.space2),
          if (events.isEmpty)
            Os2Text.body(
              'No events yet. Tap a level above.',
              color: Os2.inkMid,
              size: Os2.textSm,
            ),
          for (final e in events.take(8))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Color(e.level.tone),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Os2Text.monoCap(
                          '${e.level.handle} · ${e.kind}',
                          color: Color(e.level.tone),
                          size: Os2.textTiny,
                        ),
                        Os2Text.body(
                          e.message,
                          color: Os2.inkMid,
                          size: Os2.textSm,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
            'TelemetryService fans every event out to every enabled sink. Sink failures never cascade — a Sentry outage cannot break local logging. Sinks ship today: BufferTelemetrySink (in-memory operator buffer), ConsoleTelemetrySink (debugPrint), SentryTelemetrySink (Sentry-compatible HTTP envelope).',
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
          const SizedBox(height: Os2.space3),
          Os2Text.body(
            'Sentry — DSN supplied via --dart-define=SENTRY_DSN=… Idle when missing. Compatible with Sentry SaaS, GlitchTip, self-hosted. Pending events are buffered up to 32 entries and retried on the next submit.',
            color: Os2.inkMid,
            size: Os2.textSm,
          ),
        ],
      ),
    );
  }
}
