import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../core/render_profile.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/section_header.dart';
import 'theme_prefs_provider.dart';

/// Reusable sub-screens routed from /settings/*. Each screen targets
/// one cluster of preferences; rows are dense, two-line, with toggles
/// or chevrons. State is local-only for now (cosmetic) so the surface
/// can ship without persistence-layer regressions.

// ── Appearance ────────────────────────────────────────────────────

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(themePrefsProvider);
    final notifier = ref.read(themePrefsProvider.notifier);
    final quality = ref.watch(renderProfileProvider);
    final qualityNotifier = ref.read(renderProfileProvider.notifier);

    return PageScaffold(
      title: 'Appearance',
      subtitle: 'Theme · Accent · Density · Motion',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Caption('Theme mode'),
                  const SizedBox(height: AppTokens.space2),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final m in ThemeMode.values)
                        _PillToggle(
                          label: switch (m) {
                            ThemeMode.system => 'System',
                            ThemeMode.light => 'Light',
                            ThemeMode.dark => 'Dark',
                          },
                          selected: prefs.themeMode == m,
                          onTap: () => notifier.setThemeMode(m),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Motion & blur', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 120),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Column(
                children: [
                  _ToggleRow(
                      icon: Icons.contrast_rounded,
                      label: 'High contrast',
                      sub: 'Stronger borders + flatter glass',
                      value: prefs.highContrast,
                      onChanged: (_) => notifier.toggleHighContrast()),
                  _ToggleRow(
                      icon: Icons.blur_off_rounded,
                      label: 'Reduce transparency',
                      sub: 'Disable backdrop blur in cards',
                      value: prefs.reduceTransparency,
                      onChanged: (_) => notifier.toggleReduceTransparency()),
                  _ToggleRow(
                      icon: Icons.bedtime_rounded,
                      label: 'Auto theme by time',
                      sub: 'Switch dark/light by sunrise + sunset',
                      value: prefs.autoTheme,
                      onChanged: (_) => notifier.toggleAutoTheme()),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Render quality', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 160),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Caption('Cinematic detail'),
                  const SizedBox(height: AppTokens.space2),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final q in RenderQuality.values)
                        _PillToggle(
                          label: switch (q) {
                            RenderQuality.reduced => 'Reduced',
                            RenderQuality.normal => 'Normal',
                            RenderQuality.max => 'Max',
                          },
                          selected: quality == q,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            qualityNotifier.setQuality(q);
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }
}

// ── Notifications ────────────────────────────────────────────────

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});
  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsState();
}

class _NotificationsSettingsState extends State<NotificationsSettingsScreen> {
  bool _push = true;
  bool _email = false;
  bool _gateChange = true;
  bool _delayWarning = true;
  bool _docExpiring = true;
  bool _fxAlerts = false;
  bool _social = true;
  bool _system = true;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Notifications',
      subtitle: 'Channels and per-kind toggles',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SectionHeader(title: 'Channels', dense: true),
          AnimatedAppearance(
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Column(children: [
                _ToggleRow(
                    icon: Icons.smartphone_rounded,
                    label: 'Push',
                    sub: 'On-device alerts',
                    value: _push,
                    onChanged: (v) => setState(() => _push = v)),
                _ToggleRow(
                    icon: Icons.email_rounded,
                    label: 'Email',
                    sub: 'Weekly digest + critical alerts',
                    value: _email,
                    onChanged: (v) => setState(() => _email = v)),
              ]),
            ),
          ),
          const SectionHeader(title: 'Per-category', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 120),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Column(children: [
                _ToggleRow(
                    icon: Icons.airplane_ticket_rounded,
                    label: 'Gate changes',
                    sub: 'Real-time gate + terminal updates',
                    value: _gateChange,
                    onChanged: (v) => setState(() => _gateChange = v)),
                _ToggleRow(
                    icon: Icons.timer_rounded,
                    label: 'Delay warnings',
                    sub: 'Predictive risk before official update',
                    value: _delayWarning,
                    onChanged: (v) => setState(() => _delayWarning = v)),
                _ToggleRow(
                    icon: Icons.event_available_rounded,
                    label: 'Document expiry',
                    sub: 'Passport · visa · license countdown',
                    value: _docExpiring,
                    onChanged: (v) => setState(() => _docExpiring = v)),
                _ToggleRow(
                    icon: Icons.currency_exchange_rounded,
                    label: 'FX rate alerts',
                    sub: 'Notify when watchlisted pairs move',
                    value: _fxAlerts,
                    onChanged: (v) => setState(() => _fxAlerts = v)),
                _ToggleRow(
                    icon: Icons.people_alt_rounded,
                    label: 'Social',
                    sub: 'Friends nearby · check-ins',
                    value: _social,
                    onChanged: (v) => setState(() => _social = v)),
                _ToggleRow(
                    icon: Icons.bolt_rounded,
                    label: 'System',
                    sub: 'New features · maintenance',
                    value: _system,
                    onChanged: (v) => setState(() => _system = v)),
              ]),
            ),
          ),
          const SectionHeader(title: 'Quiet hours', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 240),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Caption('22:00 → 07:00'),
                  const SizedBox(height: 4),
                  Text('Critical only',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: AppTokens.space2),
                  Text(
                      'Travel-stage notifications and security alerts will still come through.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.60))),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }
}

// ── Security ─────────────────────────────────────────────────────

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});
  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsState();
}

class _SecuritySettingsState extends State<SecuritySettingsScreen> {
  bool _biometric = true;
  bool _passcode = true;
  bool _autoLock = true;
  bool _hideContent = false;
  bool _alertNewSignin = true;
  bool _twoFactor = true;
  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Security & sign-in',
      subtitle: 'Lock + verify + protect',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SectionHeader(title: 'Lock', dense: true),
          AnimatedAppearance(
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Column(children: [
                _ToggleRow(
                    icon: Icons.fingerprint_rounded,
                    label: 'Biometric unlock',
                    sub: 'Face / Touch / device biometrics',
                    value: _biometric,
                    onChanged: (v) => setState(() => _biometric = v)),
                _ToggleRow(
                    icon: Icons.dialpad_rounded,
                    label: 'App passcode',
                    sub: '6-digit fallback',
                    value: _passcode,
                    onChanged: (v) => setState(() => _passcode = v)),
                _ToggleRow(
                    icon: Icons.timer_rounded,
                    label: 'Auto-lock after inactivity',
                    sub: '30s when off-screen',
                    value: _autoLock,
                    onChanged: (v) => setState(() => _autoLock = v)),
                _ToggleRow(
                    icon: Icons.visibility_off_rounded,
                    label: 'Hide content in app switcher',
                    sub: 'Mask sensitive surfaces in previews',
                    value: _hideContent,
                    onChanged: (v) => setState(() => _hideContent = v)),
              ]),
            ),
          ),
          const SectionHeader(title: 'Sign-in', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 120),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Column(children: [
                _ToggleRow(
                    icon: Icons.shield_rounded,
                    label: 'Two-factor required',
                    sub: 'TOTP + backup codes',
                    value: _twoFactor,
                    onChanged: (v) => setState(() => _twoFactor = v)),
                _ToggleRow(
                    icon: Icons.notifications_active_rounded,
                    label: 'Alert on new sign-in',
                    sub: 'Email + push on every device add',
                    value: _alertNewSignin,
                    onChanged: (v) => setState(() => _alertNewSignin = v)),
              ]),
            ),
          ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }
}

// ── Privacy ───────────────────────────────────────────────────────

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});
  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsState();
}

class _PrivacySettingsState extends State<PrivacySettingsScreen> {
  bool _publicProfile = false;
  bool _showOnMap = true;
  bool _shareTrips = false;
  bool _analytics = true;
  bool _personalization = true;
  bool _sellData = false;
  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Privacy & data',
      subtitle: 'Visibility · sharing · downloads',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SectionHeader(title: 'Visibility', dense: true),
          AnimatedAppearance(
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Column(children: [
                _ToggleRow(
                    icon: Icons.public_rounded,
                    label: 'Public profile',
                    sub: 'Searchable by other GlobeID users',
                    value: _publicProfile,
                    onChanged: (v) => setState(() => _publicProfile = v)),
                _ToggleRow(
                    icon: Icons.location_on_rounded,
                    label: 'Show me on the map',
                    sub: 'Visible to mutual contacts',
                    value: _showOnMap,
                    onChanged: (v) => setState(() => _showOnMap = v)),
                _ToggleRow(
                    icon: Icons.share_rounded,
                    label: 'Share trips automatically',
                    sub: 'Friends see check-ins as they happen',
                    value: _shareTrips,
                    onChanged: (v) => setState(() => _shareTrips = v)),
              ]),
            ),
          ),
          const SectionHeader(title: 'Data', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 120),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Column(children: [
                _ToggleRow(
                    icon: Icons.bar_chart_rounded,
                    label: 'Usage analytics',
                    sub: 'Anonymized telemetry',
                    value: _analytics,
                    onChanged: (v) => setState(() => _analytics = v)),
                _ToggleRow(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Personalization',
                    sub: 'AI-shaped suggestions',
                    value: _personalization,
                    onChanged: (v) => setState(() => _personalization = v)),
                _ToggleRow(
                    icon: Icons.local_offer_rounded,
                    label: 'Allow data partners',
                    sub: 'Sell anonymized travel data',
                    value: _sellData,
                    onChanged: (v) => setState(() => _sellData = v)),
              ]),
            ),
          ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }
}

// ── Travel preferences ────────────────────────────────────────────

class TravelPrefsScreen extends StatefulWidget {
  const TravelPrefsScreen({super.key});
  @override
  State<TravelPrefsScreen> createState() => _TravelPrefsState();
}

class _TravelPrefsState extends State<TravelPrefsScreen> {
  String _cabin = 'Business';
  String _seat = 'Window';
  String _meal = 'Vegetarian';
  bool _alliancePriority = true;
  bool _redEyeAvoid = true;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Travel preferences',
      subtitle: 'Cabin · seat · meal · loyalty',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SectionHeader(title: 'Default cabin', dense: true),
          _ChoiceCard(
              choices: const ['Economy', 'Premium', 'Business', 'First'],
              selected: _cabin,
              onSelect: (v) => setState(() => _cabin = v)),
          const SectionHeader(title: 'Default seat', dense: true),
          _ChoiceCard(
              choices: const ['Window', 'Aisle', 'No preference'],
              selected: _seat,
              onSelect: (v) => setState(() => _seat = v)),
          const SectionHeader(title: 'Meal preference', dense: true),
          _ChoiceCard(choices: const [
            'Standard',
            'Vegetarian',
            'Vegan',
            'Halal',
            'Kosher',
            'Gluten-free',
          ], selected: _meal, onSelect: (v) => setState(() => _meal = v)),
          const SectionHeader(title: 'Loyalty rules', dense: true),
          AnimatedAppearance(
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Column(children: [
                _ToggleRow(
                    icon: Icons.connecting_airports_rounded,
                    label: 'Alliance priority',
                    sub: 'Star Alliance > oneworld > SkyTeam',
                    value: _alliancePriority,
                    onChanged: (v) => setState(() => _alliancePriority = v)),
                _ToggleRow(
                    icon: Icons.dark_mode_rounded,
                    label: 'Avoid red-eye flights',
                    sub: 'Skip 23:00–04:00 departures',
                    value: _redEyeAvoid,
                    onChanged: (v) => setState(() => _redEyeAvoid = v)),
              ]),
            ),
          ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }
}

// ── Accessibility ─────────────────────────────────────────────────

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});
  @override
  State<AccessibilitySettingsScreen> createState() =>
      _AccessibilitySettingsState();
}

class _AccessibilitySettingsState extends State<AccessibilitySettingsScreen> {
  double _textScale = 1.0;
  bool _largeIcons = false;
  bool _underlineLinks = false;
  bool _captions = false;
  bool _vibrations = true;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Accessibility',
      subtitle: 'Text · contrast · motion · feedback',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Caption('Text size'),
                  Slider(
                      value: _textScale,
                      min: 0.85,
                      max: 1.4,
                      divisions: 11,
                      label: '${_textScale.toStringAsFixed(2)}×',
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _textScale = v);
                      }),
                  Text('Aa Aa Aa',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontSize: 22 * _textScale)),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Visual', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 120),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Column(children: [
                _ToggleRow(
                    icon: Icons.zoom_in_rounded,
                    label: 'Larger icons',
                    sub: '+12% across all glyphs',
                    value: _largeIcons,
                    onChanged: (v) => setState(() => _largeIcons = v)),
                _ToggleRow(
                    icon: Icons.format_underlined_rounded,
                    label: 'Underline links',
                    sub: 'Always show link affordance',
                    value: _underlineLinks,
                    onChanged: (v) => setState(() => _underlineLinks = v)),
                _ToggleRow(
                    icon: Icons.closed_caption_rounded,
                    label: 'Always show captions',
                    sub: 'Inline labels under iconography',
                    value: _captions,
                    onChanged: (v) => setState(() => _captions = v)),
              ]),
            ),
          ),
          const SectionHeader(title: 'Feedback', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 200),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Column(children: [
                _ToggleRow(
                    icon: Icons.vibration_rounded,
                    label: 'Haptic feedback',
                    sub: 'Tactile cues on press',
                    value: _vibrations,
                    onChanged: (v) => setState(() => _vibrations = v)),
              ]),
            ),
          ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }
}

// ── Lab ───────────────────────────────────────────────────────────

class LabSettingsScreen extends StatefulWidget {
  const LabSettingsScreen({super.key});
  @override
  State<LabSettingsScreen> createState() => _LabSettingsState();
}

class _LabSettingsState extends State<LabSettingsScreen> {
  bool _holographic = true;
  bool _passportV2 = true;
  bool _aiCopilot = true;
  bool _streamArc = false;
  bool _proxyVision = false;
  bool _localLLM = false;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Lab features',
      subtitle: 'Experimental + early access',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: Row(children: [
                const Icon(Icons.science_rounded, color: Color(0xFFEAB308)),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: Text(
                    'These features are unstable, undocumented, and may change without warning.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ]),
            ),
          ),
          const SectionHeader(title: 'Visual', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 120),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Column(children: [
                _ToggleRow(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Holographic foil',
                    sub: 'Anisotropic foil shader on documents',
                    value: _holographic,
                    onChanged: (v) => setState(() => _holographic = v)),
                _ToggleRow(
                    icon: Icons.book_rounded,
                    label: 'Passport v2 cover-flip',
                    sub: 'New page-turn motion system',
                    value: _passportV2,
                    onChanged: (v) => setState(() => _passportV2 = v)),
                _ToggleRow(
                    icon: Icons.show_chart_rounded,
                    label: 'Streaming arc playback',
                    sub: 'Real-time flight ribbon on globe',
                    value: _streamArc,
                    onChanged: (v) => setState(() => _streamArc = v)),
              ]),
            ),
          ),
          const SectionHeader(title: 'Intelligence', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 200),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Column(children: [
                _ToggleRow(
                    icon: Icons.smart_toy_rounded,
                    label: 'AI copilot',
                    sub: 'Streaming concierge in /copilot',
                    value: _aiCopilot,
                    onChanged: (v) => setState(() => _aiCopilot = v)),
                _ToggleRow(
                    icon: Icons.remove_red_eye_rounded,
                    label: 'Proxy Vision',
                    sub: 'On-device passport scan with bounding boxes',
                    value: _proxyVision,
                    onChanged: (v) => setState(() => _proxyVision = v)),
                _ToggleRow(
                    icon: Icons.memory_rounded,
                    label: 'Local LLM',
                    sub: 'Run small models on-device',
                    value: _localLLM,
                    onChanged: (v) => setState(() => _localLLM = v)),
              ]),
            ),
          ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }
}

// ── About ─────────────────────────────────────────────────────────

class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return PageScaffold(
      title: 'About',
      subtitle: 'Version · open source · credits',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space5),
              child: Column(children: [
                Text('GlobeID',
                    style: t.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('1.0.0 · build 2026.05',
                    style: t.textTheme.bodySmall?.copyWith(
                        color:
                            t.colorScheme.onSurface.withValues(alpha: 0.60))),
                const SizedBox(height: AppTokens.space4),
                Text(
                  'A flagship global identity, travel and wallet ecosystem. Built to feel like the universal operating system for humanity.',
                  textAlign: TextAlign.center,
                  style: t.textTheme.bodyMedium,
                ),
              ]),
            ),
          ),
          const SectionHeader(title: 'Build', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 120),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Column(children: [
                _StaticRow(label: 'Channel', value: 'Stable'),
                _StaticRow(label: 'Flutter', value: '3.32'),
                _StaticRow(label: 'Dart', value: '3.5'),
                _StaticRow(label: 'Server', value: 'globeid-server v0.0.0'),
              ]),
            ),
          ),
          const SectionHeader(title: 'Legal', dense: true),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 200),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Column(children: const [
                _StaticRow(label: 'Privacy policy', value: 'Read'),
                _StaticRow(label: 'Terms of service', value: 'Read'),
                _StaticRow(label: 'Open-source licenses', value: 'View'),
                _StaticRow(label: 'Acknowledgements', value: 'View'),
              ]),
            ),
          ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────

class _Caption extends StatelessWidget {
  const _Caption(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Text(
      text,
      style: t.textTheme.labelSmall?.copyWith(
        letterSpacing: 0.6,
        color: t.colorScheme.onSurface.withValues(alpha: 0.55),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
      child: Row(
        children: [
          Icon(icon,
              size: 20, color: t.colorScheme.onSurface.withValues(alpha: 0.78)),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: t.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(sub,
                    style: t.textTheme.bodySmall?.copyWith(
                        color:
                            t.colorScheme.onSurface.withValues(alpha: 0.60))),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (v) {
              HapticFeedback.lightImpact();
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _PillToggle extends StatelessWidget {
  const _PillToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final accent = t.colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: AppTokens.durationMd,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          color: selected
              ? accent.withValues(alpha: 0.18)
              : t.colorScheme.onSurface.withValues(alpha: 0.04),
          border: Border.all(
            color: selected
                ? accent
                : t.colorScheme.onSurface.withValues(alpha: 0.10),
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: selected ? accent : t.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.choices,
    required this.selected,
    required this.onSelect,
  });
  final List<String> choices;
  final String selected;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) {
    return AnimatedAppearance(
      child: PremiumCard(
        padding: const EdgeInsets.all(AppTokens.space3),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in choices)
              _PillToggle(
                  label: c, selected: selected == c, onTap: () => onSelect(c)),
          ],
        ),
      ),
    );
  }
}

class _StaticRow extends StatelessWidget {
  const _StaticRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: t.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700))),
          Text(value,
              style: t.textTheme.bodySmall?.copyWith(
                  color: t.colorScheme.onSurface.withValues(alpha: 0.60))),
        ],
      ),
    );
  }
}
