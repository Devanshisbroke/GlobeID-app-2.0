import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../app/theme/app_tokens.dart';
import '../../cinematic/sheets/apple_sheet.dart';
import '../../domain/voice_intents.dart';
import '../../widgets/pressable.dart';
import '../../widgets/toast.dart';
import '../lifecycle/lifecycle_provider.dart';
import '../score/score_provider.dart';
import '../user/user_provider.dart';
import '../wallet/wallet_provider.dart';

class VoiceCommandOrb extends StatelessWidget {
  const VoiceCommandOrb({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: 'Voice command',
      child: Pressable(
        scale: 0.92,
        semanticLabel: 'Voice command',
        semanticHint: 'opens the voice copilot',
        onTap: () {
          HapticFeedback.mediumImpact();
          showAppleSheet<void>(
            context: context,
            eyebrow: 'COPILOT · VOICE',
            title: 'Voice command',
            detents: const [0.55, 0.78, 0.95],
            builder: (controller) => _VoiceCommandSheet(controller: controller),
          );
        },
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.secondary,
                theme.colorScheme.primary,
              ],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.20),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.28),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.mic_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _VoiceCommandSheet extends ConsumerStatefulWidget {
  const _VoiceCommandSheet({this.controller});
  final ScrollController? controller;

  @override
  ConsumerState<_VoiceCommandSheet> createState() => _VoiceCommandSheetState();
}

class _VoiceCommandSheetState extends ConsumerState<_VoiceCommandSheet>
    with SingleTickerProviderStateMixin {
  final _speech = stt.SpeechToText();
  final _manualController = TextEditingController();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  bool _initialising = false;
  bool _available = false;
  bool _listening = false;
  double _level = 0;
  String _status = 'Tap listen or type a command';
  String _transcript = '';
  VoiceIntent? _intent;
  List<String> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startListening());
  }

  @override
  void dispose() {
    _speech.cancel();
    _manualController.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _ensureReady() async {
    if (_available || _initialising) return;
    setState(() {
      _initialising = true;
      _status = 'Preparing microphone';
    });
    final ready = await _speech.initialize(
      onError: _onSpeechError,
      onStatus: _onSpeechStatus,
      options: [stt.SpeechToText.androidNoBluetooth],
      finalTimeout: const Duration(milliseconds: 900),
    );
    if (!mounted) return;
    setState(() {
      _available = ready;
      _initialising = false;
      _status = ready
          ? 'Listening stays on device when supported'
          : 'Speech recognition unavailable';
    });
  }

  Future<void> _startListening() async {
    await _ensureReady();
    if (!_available || _speech.isListening) return;
    HapticFeedback.lightImpact();
    setState(() {
      _transcript = '';
      _intent = null;
      _suggestions = const [];
      _listening = true;
      _status = 'Listening';
    });
    await _speech.listen(
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(milliseconds: 1500),
      onResult: _onSpeechResult,
      onSoundLevelChange: (level) {
        if (!mounted) return;
        setState(() => _level = level);
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        onDevice: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      ),
    );
  }

  Future<void> _stopListening() async {
    if (_speech.isListening) await _speech.stop();
    if (!mounted) return;
    setState(() {
      _listening = false;
      _status = _transcript.isEmpty ? 'Stopped' : 'Ready to execute';
    });
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords.trim();
    if (!mounted || words.isEmpty) return;
    setState(() {
      _transcript = words;
      _intent = parseVoiceIntent(words);
      _suggestions = _intent is UnknownIntent
          ? suggestVoiceIntents(words, max: 3)
          : const [];
      if (result.finalResult) {
        _listening = false;
        _status = 'Command captured';
      }
    });
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() {
      _listening = false;
      _status = error.errorMsg.replaceAll('_', ' ');
    });
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    setState(() {
      _listening = status == stt.SpeechToText.listeningStatus;
      if (status == stt.SpeechToText.doneStatus && _transcript.isNotEmpty) {
        _status = 'Ready to execute';
      }
    });
  }

  void _parseManual(String value) {
    final text = value.trim();
    setState(() {
      _transcript = text;
      _intent = text.isEmpty ? null : parseVoiceIntent(text);
      _suggestions = _intent is UnknownIntent
          ? suggestVoiceIntents(text, max: 3)
          : const [];
      _status = text.isEmpty ? 'Tap listen or type a command' : 'Typed command';
    });
  }

  Future<void> _execute([String? override]) async {
    final text = (override ?? _transcript).trim();
    if (text.isEmpty) return;
    await _stopListening();
    final intent = parseVoiceIntent(text);
    if (!mounted) return;
    final handled = await _dispatchIntent(context, ref, intent);
    if (!mounted) return;
    if (handled) {
      Navigator.of(context).maybePop();
    } else {
      setState(() {
        _intent = intent;
        _suggestions = suggestVoiceIntents(text, max: 3);
        _status = 'Try a suggested command';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final intent = _intent;
    final tone = _toneFor(intent, theme);
    final level = ((_level + 2) / 18).clamp(0.0, 1.0);

    // AppleSheet provides the substrate, drag handle, gold hairline,
    // eyebrow, and title; only the voice command body lives here.
    return ListView(
      controller: widget.controller,
      padding: EdgeInsets.fromLTRB(
        AppTokens.space5,
        AppTokens.space2,
        AppTokens.space5,
        AppTokens.space5 + bottom,
      ),
      children: [
        Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                  Row(
                    children: [
                      _ListeningOrb(
                        animation: _pulse,
                        listening: _listening,
                        level: level,
                        tone: tone,
                      ),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: Text(
                          _status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.62),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.space4),
                  AnimatedContainer(
                    duration: AppTokens.durationMd,
                    curve: AppTokens.easeOutSoft,
                    padding: const EdgeInsets.all(AppTokens.space4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTokens.radius2xl),
                      gradient: LinearGradient(
                        colors: [
                          tone.withValues(alpha: 0.18),
                          tone.withValues(alpha: 0.04),
                        ],
                      ),
                      border: Border.all(
                        color: tone.withValues(alpha: 0.24),
                        width: 0.7,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _transcript.isEmpty
                              ? 'Say "open wallet", "trip 1", or "book a hotel in Tokyo".'
                              : _transcript,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: AppTokens.space3),
                        _IntentPreview(intent: intent, tone: tone),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.space3),
                  TextField(
                    controller: _manualController,
                    onChanged: _parseManual,
                    onSubmitted: (_) => _execute(),
                    decoration: InputDecoration(
                      hintText: 'Type a command instead',
                      prefixIcon: const Icon(Icons.keyboard_rounded),
                      filled: true,
                      fillColor:
                          theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusFull),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (_suggestions.isNotEmpty) ...[
                    const SizedBox(height: AppTokens.space3),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final suggestion in _suggestions)
                          Pressable(
                            scale: 0.96,
                            onTap: () => _execute(suggestion),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppTokens.radiusFull,
                                ),
                                color: tone.withValues(alpha: 0.14),
                                border: Border.all(
                                  color: tone.withValues(alpha: 0.26),
                                ),
                              ),
                              child: Text(
                                suggestion,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: tone,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppTokens.space4),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _initialising
                              ? null
                              : (_listening ? _stopListening : _startListening),
                          icon: Icon(
                            _listening ? Icons.stop_rounded : Icons.mic_rounded,
                          ),
                          label: Text(_listening ? 'Stop' : 'Listen'),
                        ),
                      ),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _transcript.trim().isEmpty
                              ? null
                              : () => _execute(),
                          icon: const Icon(Icons.bolt_rounded),
                          label: const Text('Execute command'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ],
    );
  }

  Color _toneFor(VoiceIntent? intent, ThemeData theme) {
    if (intent == null) return theme.colorScheme.primary;
    if (intent is UnknownIntent) return const Color(0xFFF59E0B);
    if (intent is NavigateIntent) return const Color(0xFF06B6D4);
    if (intent is SearchIntent || intent is ComposeIntent) {
      return const Color(0xFF10B981);
    }
    if (intent is QueryIntent) return const Color(0xFF7C3AED);
    if (intent is RemindIntent) return const Color(0xFFEC4899);
    return theme.colorScheme.primary;
  }
}

class _ListeningOrb extends StatelessWidget {
  const _ListeningOrb({
    required this.animation,
    required this.listening,
    required this.level,
    required this.tone,
  });

  final Animation<double> animation;
  final bool listening;
  final double level;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final pulse = listening
            ? 0.65 + 0.35 * Curves.easeInOut.transform(animation.value)
            : 0.55;
        final radius = 26.0 + 10.0 * math.max(level, listening ? pulse : 0);
        return SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: AppTokens.durationSm,
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tone.withValues(alpha: listening ? 0.18 : 0.08),
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [tone, tone.withValues(alpha: 0.62)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tone.withValues(alpha: 0.34),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Icon(
                  listening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IntentPreview extends StatelessWidget {
  const _IntentPreview({required this.intent, required this.tone});

  final VoiceIntent? intent;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = switch (intent) {
      null => 'Waiting for command',
      UnknownIntent() => 'Needs clarification',
      NavigateIntent(:final path) => 'Navigate -> $path',
      ActionIntent(:final action) => 'Action -> $action',
      QueryIntent(:final query) => 'Query -> $query',
      SearchIntent(:final target) => 'Search -> $target',
      NumericIntent(:final target, :final index) => 'Open $target $index',
      TranslateIntent(:final toLang) => 'Translate -> $toLang',
      RemindIntent(:final text, :final whenLocal) =>
        'Reminder -> $text${whenLocal == null ? '' : ' at $whenLocal'}',
      ComposeIntent(:final subject, :final meta) =>
        'Compose -> $subject ${meta.values.join(' ')}'.trim(),
    };
    final icon = switch (intent) {
      NavigateIntent() => Icons.near_me_rounded,
      ActionIntent() => Icons.bolt_rounded,
      QueryIntent() => Icons.query_stats_rounded,
      SearchIntent() => Icons.search_rounded,
      NumericIntent() => Icons.pin_rounded,
      TranslateIntent() => Icons.translate_rounded,
      RemindIntent() => Icons.notifications_active_rounded,
      ComposeIntent() => Icons.auto_awesome_rounded,
      UnknownIntent() => Icons.help_outline_rounded,
      null => Icons.hearing_rounded,
    };
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tone.withValues(alpha: 0.18),
          ),
          child: Icon(icon, size: 16, color: tone),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

Future<bool> _dispatchIntent(
  BuildContext context,
  WidgetRef ref,
  VoiceIntent intent,
) async {
  if (intent is NavigateIntent) {
    _route(context, intent.path);
    _toast(context, 'Opening ${intent.label}', intent.path);
    return true;
  }
  if (intent is SearchIntent) {
    final path = switch (intent.target) {
      'hotels' => '/services/hotels',
      'rides' => '/services/rides',
      'food' => '/services/food',
      'visa' => '/services',
      _ => '/services',
    };
    _route(context, path);
    _toast(context, intent.label, path);
    return true;
  }
  if (intent is ComposeIntent) {
    final path = switch (intent.subject) {
      'hotel' => '/services/hotels',
      'ride' => '/services/rides',
      'flight' || 'trip' => '/planner',
      _ => '/planner',
    };
    _route(context, path);
    final place = intent.meta['place'];
    final when = intent.meta['when'];
    _toast(
      context,
      intent.label,
      [if (place != null) place, if (when != null) when].join(' - '),
    );
    return true;
  }
  if (intent is ActionIntent) {
    switch (intent.action) {
      case 'refresh':
        await Future.wait([
          ref.read(walletProvider.notifier).hydrate(),
          ref.read(userProvider.notifier).hydrate(),
          ref.read(lifecycleProvider.notifier).hydrate(),
        ]);
        if (!context.mounted) return false;
        _toast(context, 'Refreshed', 'Wallet, identity, and trips updated');
        return true;
      case 'start-scan':
        _route(context, '/scan');
        _toast(context, 'Scanner ready', 'Frame a QR or passport MRZ');
        return true;
      case 'toggle-language':
        _route(context, '/profile');
        _toast(context, 'Language settings', 'Opened profile preferences');
        return true;
    }
  }
  if (intent is NumericIntent) {
    final ok = _resolveNumeric(context, ref, intent);
    if (!ok) {
      _toast(context, 'No ${intent.target} ${intent.index}', null,
          tone: AppToastTone.warning);
    }
    return ok;
  }
  if (intent is QueryIntent) {
    _answerQuery(context, ref, intent);
    return true;
  }
  if (intent is TranslateIntent) {
    _toast(context, 'Translator staged', 'Target language: ${intent.toLang}');
    return true;
  }
  if (intent is RemindIntent) {
    _toast(
      context,
      'Reminder staged',
      intent.whenLocal == null
          ? intent.text
          : '${intent.text} at ${intent.whenLocal}',
    );
    return true;
  }
  return false;
}

void _route(BuildContext context, String path) {
  const shellPaths = {
    '/',
    '/identity',
    '/wallet',
    '/travel',
    '/services',
    '/map'
  };
  if (shellPaths.contains(path)) {
    context.go(path);
  } else {
    context.push(path);
  }
}

bool _resolveNumeric(
    BuildContext context, WidgetRef ref, NumericIntent intent) {
  final index = intent.index - 1;
  if (index < 0) return false;
  if (intent.target == 'trip') {
    final trips = ref.read(lifecycleProvider).trips;
    if (index >= trips.length) return false;
    _route(context, '/trip/${Uri.encodeComponent(trips[index].id)}');
    return true;
  }
  if (intent.target == 'pass') {
    final passes = ref
        .read(userProvider)
        .documents
        .where((doc) => doc.type == 'boarding_pass')
        .toList();
    if (index >= passes.length) return false;
    _route(context, '/pass/${Uri.encodeComponent(passes[index].id)}');
    return true;
  }
  final docs = ref.read(userProvider).documents;
  if (index >= docs.length) return false;
  _route(context, '/vault');
  _toast(context, 'Document ${intent.index}', docs[index].label);
  return true;
}

void _answerQuery(BuildContext context, WidgetRef ref, QueryIntent intent) {
  switch (intent.query) {
    case 'wallet-balance':
      final wallet = ref.read(walletProvider);
      final total = wallet.balances.fold<double>(0, (sum, b) => sum + b.amount);
      _toast(
        context,
        'Wallet balance',
        '${wallet.defaultCurrency} ${total.toStringAsFixed(2)} across ${wallet.balances.length} currencies',
      );
      break;
    case 'next-trip':
      final trips = ref.read(lifecycleProvider).trips;
      if (trips.isEmpty) {
        _toast(context, 'No upcoming trips', 'Open Planner to create one');
      } else {
        final trip = trips.first;
        _toast(context, 'Next trip', '${trip.name} - ${trip.stage}');
      }
      break;
    case 'score':
      final score = ref.read(scoreProvider);
      score.when(
        data: (s) => _toast(context, 'Identity score', '${s.score} / 1000'),
        loading: () => _toast(context, 'Identity score', 'Still loading'),
        error: (e, _) => _toast(context, 'Identity score unavailable', '$e',
            tone: AppToastTone.warning),
      );
      break;
    case 'weather':
      _route(context, '/intelligence');
      _toast(context, 'Weather briefing', 'Opened live intelligence');
      break;
  }
}

void _toast(
  BuildContext context,
  String title,
  String? message, {
  AppToastTone tone = AppToastTone.info,
}) {
  AppToast.show(
    context,
    title: title,
    message: message,
    tone: tone,
  );
}
