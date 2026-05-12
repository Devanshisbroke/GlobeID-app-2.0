import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/api/api_provider.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/pressable.dart';
import '../../widgets/toast.dart';
import 'agent_action_card.dart';
import 'concierge_command_surface.dart';

/// Copilot v2 — premium chat. Suggestion chips, bubble tails, typing
/// indicator, pressable send button, soft keyboard polish.
class CopilotScreen extends ConsumerStatefulWidget {
  const CopilotScreen({super.key});
  @override
  ConsumerState<CopilotScreen> createState() => _CopilotScreenState();
}

class _CopilotScreenState extends ConsumerState<CopilotScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = <_CopilotMsg>[];
  bool _busy = false;

  static const _suggestionGroups = <(String, List<String>)>[
    (
      'Travel',
      [
        'When does my next trip leave?',
        'Best route from JFK to LHR',
        'Pack list for Tokyo in June',
        'Lounges at NRT terminal 1',
      ]
    ),
    (
      'Wallet',
      [
        'Top spend categories this month',
        'JPY rate compared to last week',
        'Runway at current spend',
        'Largest expense last 30 days',
      ]
    ),
    (
      'Identity',
      [
        'Any visa expiring soon?',
        'My current identity tier',
        'How is my travel score computed?',
        'Which docs need renewal?',
      ]
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? prefilled]) async {
    final prompt = (prefilled ?? _ctrl.text).trim();
    if (prompt.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _msgs.add(_CopilotMsg(text: prompt, fromUser: true));
      _busy = true;
      _ctrl.clear();
    });
    _scrollToBottom();
    try {
      final res = await ref.read(globeIdApiProvider).copilotRespond(prompt);
      final reply = (res['reply'] as String?) ?? 'No response';
      setState(() => _msgs.add(_CopilotMsg(text: reply, fromUser: false)));
    } catch (_) {
      setState(() => _msgs.add(const _CopilotMsg(
            text: 'Offline. The copilot needs the server to respond.',
            fromUser: false,
          )));
    } finally {
      setState(() => _busy = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: AppTokens.durationMd,
        curve: AppTokens.easeOutSoft,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PageScaffold(
      title: 'Copilot',
      subtitle: 'Deterministic travel intelligence',
      body: Column(
        children: [
          Expanded(
            child: _msgs.isEmpty
                ? _EmptyState(
                    onPick: (q) => _send(q),
                    groups: _suggestionGroups,
                  )
                : ListView(
                    controller: _scroll,
                    physics: const BouncingScrollPhysics(),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppTokens.space3),
                    children: [
                      for (var i = 0; i < _msgs.length; i++)
                        AnimatedAppearance(
                          key: ValueKey(i),
                          child: Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppTokens.space2),
                            child: _Bubble(msg: _msgs[i]),
                          ),
                        ),
                      if (_busy)
                        const Padding(
                          padding:
                              EdgeInsets.only(left: 4, top: AppTokens.space2),
                          child: _TypingIndicator(),
                        ),
                    ],
                  ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: AppTokens.space5),
            padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space3, vertical: AppTokens.space2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusFull),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.10),
              ),
              boxShadow: AppTokens.shadowSm(),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      hintText: 'Ask copilot…',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                Pressable(
                  scale: 0.92,
                  onTap: _busy ? () {} : () => _send(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.6),
                        ],
                      ),
                      boxShadow:
                          AppTokens.shadowMd(tint: theme.colorScheme.primary),
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 18),
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

class _CopilotMsg {
  const _CopilotMsg({required this.text, required this.fromUser});
  final String text;
  final bool fromUser;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPick, required this.groups});
  final ValueChanged<String> onPick;
  final List<(String, List<String>)> groups;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedAppearance(
            child: ConciergeCommandSurface(
              title: 'Globe Concierge',
              subtitle: 'Predictive · Long-press to fan out',
              commands: [
                ConciergeCommand(
                  id: 'gate',
                  label: 'Find my gate',
                  icon: Icons.airplane_ticket_rounded,
                  onActivate: () => onPick('Where is my gate?'),
                ),
                ConciergeCommand(
                  id: 'translate',
                  label: 'Translate menu',
                  icon: Icons.translate_rounded,
                  onActivate: () => onPick('Translate this menu'),
                ),
                ConciergeCommand(
                  id: 'pack',
                  label: 'Pack list',
                  icon: Icons.luggage_rounded,
                  onActivate: () =>
                      onPick('Build a pack list for my next trip'),
                ),
                ConciergeCommand(
                  id: 'spend',
                  label: 'Spend snapshot',
                  icon: Icons.savings_rounded,
                  onActivate: () => onPick('Top spend categories this month'),
                ),
                ConciergeCommand(
                  id: 'rate',
                  label: 'FX check',
                  icon: Icons.currency_exchange_rounded,
                  onActivate: () => onPick('JPY rate compared to last week'),
                ),
                ConciergeCommand(
                  id: 'visa',
                  label: 'Visa expiry',
                  icon: Icons.task_alt_rounded,
                  onActivate: () => onPick('Any visa expiring soon?'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space5),
          AnimatedAppearance(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.4),
                  ],
                ),
                boxShadow: AppTokens.shadowMd(tint: theme.colorScheme.primary),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 80),
            child: Text(
              'Ask Copilot anything',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 140),
            child: Text(
              'Local-first, deterministic. No hallucinations.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space5),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 180),
            child: Text(
              'Recent agent moves',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space2),
          for (var ai = 0; ai < AgentAction.demoActions().length; ai++)
            AnimatedAppearance(
              delay: Duration(milliseconds: 220 + 60 * ai),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space2),
                child: AgentActionCard(
                  action: AgentAction.demoActions()[ai],
                ),
              ),
            ),
          for (var gi = 0; gi < groups.length; gi++) ...[
            const SizedBox(height: AppTokens.space4),
            AnimatedAppearance(
              delay: Duration(milliseconds: 200 + 80 * gi),
              child: Text(
                groups[gi].$1.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const SizedBox(height: AppTokens.space2),
            AnimatedAppearance(
              delay: Duration(milliseconds: 240 + 80 * gi),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in groups[gi].$2)
                    Pressable(
                      scale: 0.97,
                      onTap: () => onPick(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusFull),
                          gradient: LinearGradient(colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.16),
                            theme.colorScheme.primary.withValues(alpha: 0.04),
                          ]),
                          border: Border.all(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.18),
                          ),
                        ),
                        child: Text(s,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final _CopilotMsg msg;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment:
          msg.fromUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppTokens.space2,
            vertical: 2,
          ).copyWith(left: msg.fromUser ? 0 : AppTokens.space3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!msg.fromUser) ...[
                Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ]),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 11,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                msg.fromUser ? 'YOU' : 'COPILOT',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onLongPress: () {
            HapticFeedback.mediumImpact();
            Clipboard.setData(ClipboardData(text: msg.text));
            AppToast.show(
              context,
              title: 'Copied',
              tone: AppToastTone.neutral,
              duration: const Duration(milliseconds: 1400),
            );
          },
          child: Align(
            alignment:
                msg.fromUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space4, vertical: AppTokens.space3),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              decoration: BoxDecoration(
                gradient: msg.fromUser
                    ? LinearGradient(colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.78),
                      ])
                    : null,
                color: msg.fromUser
                    ? null
                    : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppTokens.radiusXl),
                  topRight: const Radius.circular(AppTokens.radiusXl),
                  bottomLeft: msg.fromUser
                      ? const Radius.circular(AppTokens.radiusXl)
                      : const Radius.circular(6),
                  bottomRight: msg.fromUser
                      ? const Radius.circular(6)
                      : const Radius.circular(AppTokens.radiusXl),
                ),
                boxShadow: msg.fromUser
                    ? AppTokens.shadowSm(tint: theme.colorScheme.primary)
                    : null,
              ),
              child: msg.fromUser
                  ? Text(
                      msg.text,
                      style: const TextStyle(
                        color: Colors.white,
                        height: 1.4,
                      ),
                    )
                  : _StreamingText(
                      text: msg.text,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Reveals the supplied text character-by-character on first build.
/// Used for the assistant bubble to feel like streaming output.
class _StreamingText extends StatefulWidget {
  const _StreamingText({required this.text, required this.style});
  final String text;
  final TextStyle style;
  @override
  State<_StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<_StreamingText>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: (12 * widget.text.length).clamp(400, 2400).toInt(),
    ),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final chars = (widget.text.length * _ctrl.value).round();
        return Text(
          widget.text.substring(0, chars),
          style: widget.style,
        );
      },
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppTokens.radiusXl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) {
                  final t = ((_ctrl.value - i / 3) % 1.0).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      width: 6,
                      height: 6 + 4 * t,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.4 + 0.6 * t),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
