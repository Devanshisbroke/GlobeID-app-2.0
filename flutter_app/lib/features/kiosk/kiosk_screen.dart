import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';
import '../../widgets/page_scaffold.dart';

class KioskScreen extends StatelessWidget {
  const KioskScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const PageScaffold(
      title: 'Kiosk simulator',
      subtitle: 'Practice biometric identity verification',
      body: EmptyState(
        title: 'Kiosk simulator',
        message:
            'Stand in front of a kiosk camera to simulate the identity verification flow. (Demo)',
        icon: Icons.face_retouching_natural_rounded,
      ),
    );
  }
}
