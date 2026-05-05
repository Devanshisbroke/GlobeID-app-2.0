import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../data/api/api_provider.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/page_scaffold.dart';

class CopilotScreen extends ConsumerStatefulWidget {
  const CopilotScreen({super.key});
  @override
  ConsumerState<CopilotScreen> createState() => _CopilotScreenState();
}

class _CopilotScreenState extends ConsumerState<CopilotScreen> {
  final _ctrl = TextEditingController();
  final _msgs = <_CopilotMsg>[];
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final prompt = _ctrl.text.trim();
    if (prompt.isEmpty) return;
    setState(() {
      _msgs.add(_CopilotMsg(text: prompt, fromUser: true));
      _busy = true;
      _ctrl.clear();
    });
    try {
      final res = await ref.read(globeIdApiProvider).copilotRespond(prompt);
      final reply = (res['reply'] as String?) ?? 'No response';
      setState(() => _msgs.add(_CopilotMsg(text: reply, fromUser: false)));
    } catch (e) {
      setState(() => _msgs.add(_CopilotMsg(
          text: 'Offline. The copilot needs the server to respond.',
          fromUser: false)));
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Copilot',
      subtitle: 'Deterministic travel intelligence',
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
              itemCount: _msgs.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppTokens.space2),
              itemBuilder: (_, i) => _Bubble(msg: _msgs[i]),
            ),
          ),
          GlassSurface(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.space3, vertical: AppTokens.space2),
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
                IconButton.filled(
                  onPressed: _busy ? null : _send,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space5),
        ],
      ),
    );
  }
}

class _CopilotMsg {
  _CopilotMsg({required this.text, required this.fromUser});
  final String text;
  final bool fromUser;
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final _CopilotMsg msg;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: msg.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space4, vertical: AppTokens.space3),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: msg.fromUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppTokens.radiusXl),
            topRight: const Radius.circular(AppTokens.radiusXl),
            bottomLeft: msg.fromUser
                ? const Radius.circular(AppTokens.radiusXl)
                : const Radius.circular(4),
            bottomRight: msg.fromUser
                ? const Radius.circular(4)
                : const Radius.circular(AppTokens.radiusXl),
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.fromUser ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
