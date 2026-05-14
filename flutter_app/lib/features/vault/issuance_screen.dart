import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../cinematic/identity/issuance_ceremony.dart';
import '../../os2/os2_tokens.dart';
import '../../os2/primitives/os2_text.dart';
import '../../widgets/pressable.dart';

/// Issuance screen — opens from a `Mint credential` action and
/// plays the [IssuanceCeremony]. After the ceremony settles, a
/// `RETURN TO VAULT` CTA fades in.
class IssuanceScreen extends StatefulWidget {
  const IssuanceScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.issuer,
    required this.blockHeight,
  });

  final String title;
  final String subtitle;
  final String issuer;
  final int blockHeight;

  @override
  State<IssuanceScreen> createState() => _IssuanceScreenState();
}

class _IssuanceScreenState extends State<IssuanceScreen> {
  bool _settled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Os2.canvas,
      body: Stack(
        children: [
          IssuanceCeremony(
            title: widget.title,
            subtitle: widget.subtitle,
            issuer: widget.issuer,
            blockHeight: widget.blockHeight,
            onComplete: () {
              if (mounted) setState(() => _settled = true);
            },
          ),
          if (_settled)
            Positioned(
              bottom: 28,
              left: Os2.space5,
              right: Os2.space5,
              child: AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 480),
                child: Pressable(
                  semanticLabel: 'Return to vault',
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/vault');
                    }
                  },
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      vertical: Os2.space4,
                    ),
                    decoration: BoxDecoration(
                      color: Os2.floor1,
                      borderRadius: BorderRadius.circular(Os2.rCard),
                      border: Border.all(
                        color: Os2.goldDeep.withValues(alpha: 0.62),
                      ),
                    ),
                    child: Os2Text.monoCap(
                      'RETURN TO VAULT',
                      color: Os2.goldDeep,
                      size: Os2.textTiny,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
