import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../os2_tokens.dart';
import '../primitives/os2_beacon.dart';
import '../primitives/os2_chip.dart';
import '../primitives/os2_divider_rule.dart';
import '../primitives/os2_glyph_halo.dart';
import '../primitives/os2_info_strip.dart';
import '../primitives/os2_magnetic.dart';
import '../primitives/os2_slab.dart';
import '../primitives/os2_text.dart';

/// OS 2.0 — Settings hub.
///
/// Single-screen vertically stacked surface organized into ten
/// thematic sections, each rendered as a slab. Sections:
///
///   • Profile · sovereign identity
///   • Security · vault + biometrics
///   • Privacy · data residency + sharing
///   • Sensors · motion / haptics / sound
///   • Display · theme / density / OLED
///   • Notifications · channels + standing protocols
///   • Connectivity · eSIM + roaming
///   • Treasury · accounts + autosweep
///   • Travel · documents + lanes
///   • System · build / release / audit / about
///
/// Every row uses Os2 primitives. No legacy ListTile.
class Os2SettingsScreen extends ConsumerStatefulWidget {
  const Os2SettingsScreen({super.key});

  @override
  ConsumerState<Os2SettingsScreen> createState() =>
      _Os2SettingsScreenState();
}

class _Os2SettingsScreenState extends ConsumerState<Os2SettingsScreen> {
  bool _bio = true;
  bool _telemetry = false;
  bool _haptics = true;
  bool _oled = true;
  bool _autosweep = true;
  bool _conciergePush = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Os2.canvas,
      appBar: AppBar(
        backgroundColor: Os2.canvas,
        elevation: 0,
        title: Os2Text.title('Settings', color: Os2.inkBright, size: 18),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: Os2.space2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: Row(
                  children: [
                    Os2Beacon(label: 'GLOBEID OS2', tone: Os2.identityTone),
                    const Spacer(),
                    Os2Text.monoCap('1.2.0 \u00b7 BUILD 28741',
                        color: Os2.inkMid, size: 11),
                  ],
                ),
              ),
              const SizedBox(height: Os2.space3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: _ProfileCard(),
              ),
              const SizedBox(height: Os2.space4),
              Os2InfoStrip(
                entries: const [
                  Os2InfoEntry(
                    icon: Icons.shield_rounded,
                    label: 'VAULT',
                    value: 'SEALED',
                    tone: Os2.signalSettled,
                  ),
                  Os2InfoEntry(
                    icon: Icons.fingerprint_rounded,
                    label: 'BIO',
                    value: 'ARMED',
                    tone: Os2.identityTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.security_rounded,
                    label: '2FA',
                    value: 'TOTP',
                    tone: Os2.travelTone,
                  ),
                  Os2InfoEntry(
                    icon: Icons.cloud_sync_rounded,
                    label: 'SYNC',
                    value: 'IDLE',
                    tone: Os2.inkMid,
                  ),
                  Os2InfoEntry(
                    icon: Icons.gpp_good_rounded,
                    label: 'AUDIT',
                    value: 'PASSING',
                    tone: Os2.signalSettled,
                  ),
                ],
              ),
              const SizedBox(height: Os2.space4),
              _SettingsSection(
                title: 'SECURITY',
                tone: Os2.identityTone,
                rows: [
                  _ToggleRow(
                    icon: Icons.fingerprint_rounded,
                    title: 'Biometric unlock',
                    sub: 'Face / fingerprint · auto-lock 2 min idle',
                    tone: Os2.identityTone,
                    value: _bio,
                    onChanged: (v) => setState(() => _bio = v),
                  ),
                  const _Divider(),
                  _NavRow(
                    icon: Icons.lock_clock_rounded,
                    title: 'Session lock',
                    sub: 'Auto · 2 min idle · pin 6-digit',
                    tone: Os2.identityTone,
                    route: '/settings/security',
                  ),
                  const _Divider(),
                  _NavRow(
                    icon: Icons.fact_check_rounded,
                    title: 'Audit log',
                    sub: '12 events · last 24h',
                    tone: Os2.signalSettled,
                    route: '/audit-log',
                  ),
                ],
              ),
              const SizedBox(height: Os2.space3),
              _SettingsSection(
                title: 'PRIVACY',
                tone: Os2.discoverTone,
                rows: [
                  _ToggleRow(
                    icon: Icons.bar_chart_rounded,
                    title: 'Anonymous telemetry',
                    sub: 'No PII · improves AGI suggestions',
                    tone: Os2.discoverTone,
                    value: _telemetry,
                    onChanged: (v) => setState(() => _telemetry = v),
                  ),
                  const _Divider(),
                  _NavRow(
                    icon: Icons.share_rounded,
                    title: 'Data sharing',
                    sub: '0 third-party scopes active',
                    tone: Os2.discoverTone,
                    route: '/settings/privacy',
                  ),
                ],
              ),
              const SizedBox(height: Os2.space3),
              _SettingsSection(
                title: 'SENSORS & HAPTICS',
                tone: Os2.pulseTone,
                rows: [
                  _ToggleRow(
                    icon: Icons.vibration_rounded,
                    title: 'Premium haptics',
                    sub: '9 patterns · selection, success, magnetic',
                    tone: Os2.pulseTone,
                    value: _haptics,
                    onChanged: (v) => setState(() => _haptics = v),
                  ),
                  const _Divider(),
                  _NavRow(
                    icon: Icons.sensors_rounded,
                    title: 'Sensors lab',
                    sub: 'Gyro · accelerometer · ambient',
                    tone: Os2.pulseTone,
                    route: '/sensors-lab',
                  ),
                ],
              ),
              const SizedBox(height: Os2.space3),
              _SettingsSection(
                title: 'DISPLAY',
                tone: Os2.walletTone,
                rows: [
                  _ToggleRow(
                    icon: Icons.dark_mode_rounded,
                    title: 'OLED true black',
                    sub: 'Canvas = #000 · max contrast · max battery',
                    tone: Os2.walletTone,
                    value: _oled,
                    onChanged: (v) => setState(() => _oled = v),
                  ),
                  const _Divider(),
                  _NavRow(
                    icon: Icons.text_fields_rounded,
                    title: 'Typography & density',
                    sub: 'Departure Mono · OS2 grid',
                    tone: Os2.walletTone,
                    route: '/settings/display',
                  ),
                ],
              ),
              const SizedBox(height: Os2.space3),
              _SettingsSection(
                title: 'NOTIFICATIONS',
                tone: Os2.servicesTone,
                rows: [
                  _ToggleRow(
                    icon: Icons.notifications_active_rounded,
                    title: 'Concierge push',
                    sub: 'Standing protocols · alerts · briefs',
                    tone: Os2.servicesTone,
                    value: _conciergePush,
                    onChanged: (v) => setState(() => _conciergePush = v),
                  ),
                  const _Divider(),
                  _NavRow(
                    icon: Icons.tune_rounded,
                    title: 'Channels',
                    sub: 'Travel · Treasury · Identity · Services',
                    tone: Os2.servicesTone,
                    route: '/settings/notifications',
                  ),
                ],
              ),
              const SizedBox(height: Os2.space3),
              _SettingsSection(
                title: 'CONNECTIVITY',
                tone: Os2.discoverTone,
                rows: [
                  _NavRow(
                    icon: Icons.sim_card_rounded,
                    title: 'eSIM & data plans',
                    sub: 'US Pack \u00b7 7 GB \u00b7 active',
                    tone: Os2.discoverTone,
                    route: '/esim',
                  ),
                  const _Divider(),
                  _NavRow(
                    icon: Icons.wifi_rounded,
                    title: 'Wi-Fi auto-trust',
                    sub: '14 lounges · 6 airports · 3 hotels',
                    tone: Os2.signalSettled,
                    route: '/settings/connectivity',
                  ),
                ],
              ),
              const SizedBox(height: Os2.space3),
              _SettingsSection(
                title: 'TREASURY',
                tone: Os2.walletTone,
                rows: [
                  _ToggleRow(
                    icon: Icons.cyclone_rounded,
                    title: 'Auto-sweep idle balances',
                    sub: 'Idle EUR → USD on best mid-rate',
                    tone: Os2.walletTone,
                    value: _autosweep,
                    onChanged: (v) => setState(() => _autosweep = v),
                  ),
                  const _Divider(),
                  _NavRow(
                    icon: Icons.account_balance_rounded,
                    title: 'Linked accounts',
                    sub: '3 banks · 2 ledgers · 1 vault',
                    tone: Os2.walletTone,
                    route: '/settings/accounts',
                  ),
                ],
              ),
              const SizedBox(height: Os2.space3),
              _SettingsSection(
                title: 'TRAVEL',
                tone: Os2.travelTone,
                rows: [
                  _NavRow(
                    icon: Icons.menu_book_rounded,
                    title: 'Documents & passports',
                    sub: '1 passport · 4 visas · 2 health certs',
                    tone: Os2.travelTone,
                    route: '/passport',
                  ),
                  const _Divider(),
                  _NavRow(
                    icon: Icons.verified_user_rounded,
                    title: 'Trusted-traveler programs',
                    sub: 'Global Entry · TSA Pre · NEXUS',
                    tone: Os2.identityTone,
                    route: '/identity',
                  ),
                ],
              ),
              const SizedBox(height: Os2.space3),
              _SettingsSection(
                title: 'SYSTEM',
                tone: Os2.inkHigh,
                rows: [
                  _NavRow(
                    icon: Icons.architecture_rounded,
                    title: 'Build & release',
                    sub: '1.2.0 \u00b7 build 28741 \u00b7 OS2',
                    tone: Os2.inkHigh,
                    route: '/settings/system',
                  ),
                  const _Divider(),
                  _NavRow(
                    icon: Icons.history_rounded,
                    title: 'Diagnostics',
                    sub: 'Crash-free 100% · queue depth 0',
                    tone: Os2.signalSettled,
                    route: '/settings/diagnostics',
                  ),
                  const _Divider(),
                  _NavRow(
                    icon: Icons.info_outline_rounded,
                    title: 'About GlobeID',
                    sub: 'Civilization-scale identity OS',
                    tone: Os2.pulseTone,
                    route: '/settings/about',
                  ),
                ],
              ),
              const SizedBox(height: Os2.space4),
              // Sign-out and emergency.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
                child: Row(
                  children: [
                    Expanded(
                      child: Os2Magnetic(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                            vertical: Os2.space3,
                          ),
                          decoration: ShapeDecoration(
                            color: Os2.floor2,
                            shape: ContinuousRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(Os2.rCard),
                              side: BorderSide(
                                color: Os2.hairline,
                                width: Os2.strokeFine,
                              ),
                            ),
                          ),
                          child: Os2Text.title(
                            'Lock device',
                            color: Os2.inkHigh,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Os2.space3),
                    Expanded(
                      child: Os2Magnetic(
                        onTap: () {
                          HapticFeedback.heavyImpact();
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                            vertical: Os2.space3,
                          ),
                          decoration: ShapeDecoration(
                            color: Os2.signalCritical
                                .withValues(alpha: 0.10),
                            shape: ContinuousRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(Os2.rCard),
                              side: BorderSide(
                                color: Os2.signalCritical
                                    .withValues(alpha: 0.40),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Os2Text.title(
                            'Sign out',
                            color: Os2.signalCritical,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Os2.space4),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────── Profile

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return Os2Slab(
      tone: Os2.identityTone,
      tier: Os2SlabTier.floor1,
      radius: Os2.rHero,
      halo: Os2SlabHalo.edge,
      elevation: Os2SlabElevation.cinematic,
      padding: const EdgeInsets.all(Os2.space4),
      breath: true,
      child: Row(
        children: [
          Os2GlyphHalo(
            icon: Icons.person_rounded,
            tone: Os2.identityTone,
            size: 64,
            iconSize: 32,
          ),
          const SizedBox(width: Os2.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Os2Text.monoCap('GLOBEID',
                    color: Os2.identityTone, size: 11),
                const SizedBox(height: 2),
                Os2Text.display('Devansh Bhardwaj',
                    color: Os2.inkBright, size: 22),
                const SizedBox(height: 4),
                Os2Text.caption('GLB-1024-7XK7 · Aviator tier',
                    color: Os2.inkMid),
              ],
            ),
          ),
          Os2Magnetic(
            onTap: () => GoRouter.of(context).push('/profile'),
            child: const Os2Chip(
              label: 'OPEN',
              icon: Icons.chevron_right_rounded,
              tone: Os2.identityTone,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────── Section

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.tone,
    required this.rows,
  });

  final String title;
  final Color tone;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Os2.space4),
      child: Os2Slab(
        tone: tone,
        tier: Os2SlabTier.floor2,
        radius: Os2.rCard,
        halo: Os2SlabHalo.corner,
        padding: const EdgeInsets.all(Os2.space4),
        breath: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Os2DividerRule(
              eyebrow: title,
              tone: tone,
            ),
            const SizedBox(height: Os2.space3),
            for (final r in rows) r,
          ],
        ),
      ),
    );
  }
}

// ───────── Rows

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.sub,
    required this.tone,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String sub;
  final Color tone;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Os2Magnetic(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Os2.space2),
        child: Row(
          children: [
            Os2GlyphHalo(icon: icon, tone: tone, size: 36),
            const SizedBox(width: Os2.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Os2Text.title(title, color: Os2.inkBright, size: 14),
                  const SizedBox(height: 2),
                  Os2Text.caption(sub, color: Os2.inkMid),
                ],
              ),
            ),
            const SizedBox(width: Os2.space2),
            _ToggleSwitch(value: value, tone: tone),
          ],
        ),
      ),
    );
  }
}

class _ToggleSwitch extends StatelessWidget {
  const _ToggleSwitch({required this.value, required this.tone});
  final bool value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Os2.mIn,
      curve: Os2.cTakeoff,
      width: 44,
      height: 26,
      padding: const EdgeInsets.all(2),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      decoration: ShapeDecoration(
        color: value ? tone.withValues(alpha: 0.30) : Os2.floor3,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: BorderSide(
            color: value ? tone.withValues(alpha: 0.50) : Os2.hairline,
            width: 1,
          ),
        ),
      ),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: value ? tone : Os2.inkMid,
          boxShadow: value
              ? [
                  BoxShadow(
                    color: tone.withValues(alpha: 0.40),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.sub,
    required this.tone,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String sub;
  final Color tone;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Os2Magnetic(
      onTap: () {
        HapticFeedback.selectionClick();
        try {
          GoRouter.of(context).push(route);
        } catch (_) {/* route may not exist yet */}
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Os2.space2),
        child: Row(
          children: [
            Os2GlyphHalo(icon: icon, tone: tone, size: 36),
            const SizedBox(width: Os2.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Os2Text.title(title, color: Os2.inkBright, size: 14),
                  const SizedBox(height: 2),
                  Os2Text.caption(sub, color: Os2.inkMid),
                ],
              ),
            ),
            const SizedBox(width: Os2.space2),
            Icon(Icons.chevron_right_rounded,
                color: tone.withValues(alpha: 0.70), size: 18),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Os2.space1),
        child: Container(height: 1, color: Os2.hairlineSoft),
      );
}
