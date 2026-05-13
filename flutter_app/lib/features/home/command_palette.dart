import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/pressable.dart';

/// Full command palette overlay (Cmd-K style).
///
/// Search routes, actions, trips, documents. Recent commands,
/// fuzzy search, keyboard navigation. Triggered by FAB long-press
/// or pull-down gesture.
class CommandPalette extends StatefulWidget {
  const CommandPalette({super.key});

  /// Show the command palette as a modal overlay.
  static void show(BuildContext context) {
    HapticFeedback.mediumImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Command palette',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: AppTokens.easeOutSoft,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.03),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (_, __, ___) => const CommandPalette(),
    );
  }

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<_Command> get _filtered {
    if (_query.isEmpty) return _allCommands;
    final q = _query.toLowerCase();
    return _allCommands.where((cmd) {
      return cmd.label.toLowerCase().contains(q) ||
          cmd.keywords.any((k) => k.contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final results = _filtered;
    final top = MediaQuery.of(context).padding.top;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, top + 20, 16, 16),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radius2xl),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
              child: Container(
                constraints:
                    const BoxConstraints(maxWidth: 480, maxHeight: 520),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0B0F1A).withValues(alpha: 0.92)
                      : Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(AppTokens.radius2xl),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.18),
                    width: 0.7,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.32),
                      blurRadius: 48,
                      offset: const Offset(0, 24),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.space4,
                        AppTokens.space4,
                        AppTokens.space4,
                        0,
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: (v) => setState(() => _query = v),
                        onSubmitted: (_) {
                          if (results.isNotEmpty) _execute(results.first);
                        },
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search commands, routes, actions…',
                          hintStyle: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.35),
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon:
                                      const Icon(Icons.close_rounded, size: 18),
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() => _query = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: theme.colorScheme.onSurface
                              .withValues(alpha: 0.04),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusFull),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.space4,
                            vertical: AppTokens.space3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTokens.space2),
                    Divider(
                      height: 1,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.06),
                    ),
                    // Results
                    Flexible(
                      child: results.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(AppTokens.space6),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off_rounded,
                                      size: 36,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.25)),
                                  const SizedBox(height: AppTokens.space3),
                                  Text(
                                    'No matching commands',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.40),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppTokens.space2,
                              ),
                              itemCount: results.length,
                              itemBuilder: (_, i) {
                                final cmd = results[i];
                                return _CommandRow(
                                  command: cmd,
                                  onTap: () => _execute(cmd),
                                );
                              },
                            ),
                    ),
                    // Footer
                    Divider(
                      height: 1,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.06),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppTokens.space3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.keyboard_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.30)),
                          const SizedBox(width: 6),
                          Text(
                            'FAB long-press to summon',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.30),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _execute(_Command cmd) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
    if (cmd.route != null) {
      GoRouter.of(context).push(cmd.route!);
    }
  }
}

class _CommandRow extends StatelessWidget {
  const _CommandRow({required this.command, required this.onTap});
  final _Command command;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      semanticLabel: command.label,
      semanticHint: command.subtitle.isEmpty
          ? 'command palette action'
          : command.subtitle,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4,
          vertical: AppTokens.space2,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                color: command.tone.withValues(alpha: 0.12),
              ),
              child: Icon(command.icon, size: 16, color: command.tone),
            ),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    command.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (command.subtitle.isNotEmpty)
                    Text(
                      command.subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (command.route != null)
              Icon(Icons.chevron_right_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.25)),
          ],
        ),
      ),
    );
  }
}

class _Command {
  const _Command({
    required this.label,
    this.subtitle = '',
    required this.icon,
    this.route,
    this.tone = const Color(0xFF0EA5E9),
    this.keywords = const [],
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final String? route;
  final Color tone;
  final List<String> keywords;
}

const _allCommands = <_Command>[
  _Command(
    label: 'Home',
    subtitle: 'Dashboard & overview',
    icon: Icons.cottage_rounded,
    route: '/',
    keywords: ['home', 'dashboard', 'main'],
  ),
  _Command(
    label: 'Identity vault',
    subtitle: 'Credentials, documents, score',
    icon: Icons.verified_user_rounded,
    route: '/identity',
    tone: Color(0xFF8B5CF6),
    keywords: ['identity', 'passport', 'documents', 'vault', 'score'],
  ),
  _Command(
    label: 'Wallet',
    subtitle: 'Balances, cards, transactions',
    icon: Icons.account_balance_wallet_rounded,
    route: '/wallet',
    tone: Color(0xFF0EA5E9),
    keywords: ['wallet', 'money', 'balance', 'cards', 'pay'],
  ),
  _Command(
    label: 'Travel',
    subtitle: 'Trips, flights, itineraries',
    icon: Icons.flight_takeoff_rounded,
    route: '/travel',
    tone: Color(0xFFE11D48),
    keywords: ['travel', 'trips', 'flights', 'booking'],
  ),
  _Command(
    label: 'Services',
    subtitle: 'Hotels, rides, food, activities',
    icon: Icons.dashboard_rounded,
    route: '/services',
    tone: Color(0xFF10B981),
    keywords: ['services', 'hotels', 'rides', 'food'],
  ),
  _Command(
    label: 'Globe',
    subtitle: 'Cinematic 3D earth view',
    icon: Icons.public_rounded,
    route: '/globe-cinematic',
    tone: Color(0xFF06B6D4),
    keywords: ['globe', 'map', 'earth', 'world'],
  ),
  _Command(
    label: 'Scanner',
    subtitle: 'QR codes, passport MRZ, documents',
    icon: Icons.qr_code_scanner_rounded,
    route: '/scan',
    keywords: ['scan', 'qr', 'camera', 'passport'],
  ),
  _Command(
    label: 'Plan a trip',
    subtitle: 'Create a new travel itinerary',
    icon: Icons.edit_calendar_rounded,
    route: '/planner',
    tone: Color(0xFF7E22CE),
    keywords: ['plan', 'trip', 'new', 'create', 'itinerary'],
  ),
  _Command(
    label: 'Copilot',
    subtitle: 'AI travel assistant',
    icon: Icons.smart_toy_rounded,
    route: '/copilot',
    tone: Color(0xFF059669),
    keywords: ['ai', 'copilot', 'assistant', 'help', 'chat'],
  ),
  _Command(
    label: 'Discover',
    subtitle: 'Explore new destinations',
    icon: Icons.travel_explore_rounded,
    route: '/discover',
    tone: Color(0xFF06B6D4),
    keywords: ['discover', 'explore', 'destinations'],
  ),
  _Command(
    label: 'Multi-currency',
    subtitle: 'Exchange rates & conversion',
    icon: Icons.currency_exchange_rounded,
    route: '/multi-currency',
    tone: Color(0xFFD97706),
    keywords: ['currency', 'exchange', 'forex', 'rates'],
  ),
  _Command(
    label: 'Passport book',
    subtitle: 'Travel stamps & entries',
    icon: Icons.menu_book_rounded,
    route: '/passport-book',
    tone: Color(0xFF8B5CF6),
    keywords: ['passport', 'stamps', 'book', 'entries'],
  ),
  _Command(
    label: 'Inbox',
    subtitle: 'Notifications & alerts',
    icon: Icons.notifications_rounded,
    route: '/inbox',
    tone: Color(0xFFE11D48),
    keywords: ['inbox', 'notifications', 'alerts', 'messages'],
  ),
  _Command(
    label: 'Settings',
    subtitle: 'App preferences & configuration',
    icon: Icons.settings_rounded,
    route: '/settings',
    keywords: ['settings', 'preferences', 'config'],
  ),
  _Command(
    label: 'Profile',
    subtitle: 'Your account & preferences',
    icon: Icons.person_rounded,
    route: '/profile',
    keywords: ['profile', 'account', 'user'],
  ),
  _Command(
    label: 'Intelligence',
    subtitle: 'AI insights & briefings',
    icon: Icons.psychology_rounded,
    route: '/intelligence',
    tone: Color(0xFF6366F1),
    keywords: ['intelligence', 'insights', 'briefing', 'ai'],
  ),
  _Command(
    label: 'Emergency SOS',
    subtitle: 'Emergency contacts & services',
    icon: Icons.emergency_rounded,
    route: '/emergency',
    tone: Color(0xFFEF4444),
    keywords: ['emergency', 'sos', 'help', 'urgent'],
  ),
  _Command(
    label: 'Audit log',
    subtitle: 'Security events & access history',
    icon: Icons.security_rounded,
    route: '/audit-log',
    tone: Color(0xFFEA580C),
    keywords: ['audit', 'security', 'log', 'history'],
  ),
  _Command(
    label: 'Phrasebook',
    subtitle: 'Travel language essentials',
    icon: Icons.translate_rounded,
    route: '/phrasebook',
    tone: Color(0xFF06B6D4),
    keywords: ['phrasebook', 'translate', 'language', 'speak'],
  ),
  _Command(
    label: 'Travel OS',
    subtitle: 'Full travel operating system',
    icon: Icons.hub_rounded,
    route: '/travel-os',
    tone: Color(0xFF8B5CF6),
    keywords: ['travel', 'os', 'system', 'hub'],
  ),
  _Command(
    label: 'Airport mode',
    subtitle: 'Live gate · terminal map · timing',
    icon: Icons.flight_takeoff_rounded,
    route: '/airport-mode',
    tone: Color(0xFF2563EB),
    keywords: ['airport', 'mode', 'gate', 'terminal', 'lounge'],
  ),
  _Command(
    label: 'Super services',
    subtitle: 'Unified score · fraud · safety hub',
    icon: Icons.auto_awesome_rounded,
    route: '/super-services',
    tone: Color(0xFF7C3AED),
    keywords: ['super', 'services', 'fraud', 'score', 'safety'],
  ),
  _Command(
    label: 'Trip wallet',
    subtitle: 'Per-trip envelope · auto-tagging',
    icon: Icons.savings_rounded,
    route: '/trip-wallet',
    tone: Color(0xFF0EA5E9),
    keywords: ['trip', 'wallet', 'envelope', 'budget'],
  ),
  _Command(
    label: 'Visa center',
    subtitle: 'Eligibility · expiry · readiness',
    icon: Icons.assignment_ind_rounded,
    route: '/visa',
    tone: Color(0xFF10B981),
    keywords: ['visa', 'entry', 'passport', 'document'],
  ),
  _Command(
    label: 'Vault',
    subtitle: 'Documents, IDs, sealed proofs',
    icon: Icons.shield_moon_rounded,
    route: '/vault',
    tone: Color(0xFFEA580C),
    keywords: ['vault', 'document', 'storage', 'secure'],
  ),
  _Command(
    label: 'Lounge map',
    subtitle: 'Find a lounge near your gate',
    icon: Icons.airline_seat_recline_extra_rounded,
    route: '/lounge',
    tone: Color(0xFF8B5CF6),
    keywords: ['lounge', 'priority pass', 'rest'],
  ),
  _Command(
    label: 'eSIM',
    subtitle: 'Local data plan + auto-activate',
    icon: Icons.sim_card_rounded,
    route: '/esim',
    tone: Color(0xFF22D3EE),
    keywords: ['esim', 'sim', 'data', 'roaming'],
  ),
  _Command(
    label: 'Customs declaration',
    subtitle: 'Pre-fill arrival forms',
    icon: Icons.fact_check_rounded,
    route: '/customs',
    tone: Color(0xFFF59E0B),
    keywords: ['customs', 'declaration', 'arrival'],
  ),
  _Command(
    label: 'Packing checklist',
    subtitle: 'Smart packing per trip',
    icon: Icons.checklist_rounded,
    route: '/packing',
    tone: Color(0xFF14B8A6),
    keywords: ['packing', 'checklist', 'luggage'],
  ),
  _Command(
    label: 'Trip journal',
    subtitle: 'Captured moments per leg',
    icon: Icons.menu_book_rounded,
    route: '/journal',
    tone: Color(0xFFA855F7),
    keywords: ['journal', 'memories', 'log'],
  ),
  _Command(
    label: 'Country profile',
    subtitle: 'Costs, climate, customs',
    icon: Icons.public_rounded,
    route: '/country',
    tone: Color(0xFF0EA5E9),
    keywords: ['country', 'destination', 'profile'],
  ),
  _Command(
    label: 'Kiosk simulator',
    subtitle: 'Live e-gate / kiosk demo',
    icon: Icons.point_of_sale_rounded,
    route: '/kiosk-sim',
    tone: Color(0xFF7C3AED),
    keywords: ['kiosk', 'gate', 'simulator'],
  ),
  _Command(
    label: 'Sensors lab',
    subtitle: 'Live device intelligence',
    icon: Icons.sensors_rounded,
    route: '/sensors-lab',
    tone: Color(0xFF8B5CF6),
    keywords: ['sensors', 'lab', 'device'],
  ),
  _Command(
    label: 'Premium showcase',
    subtitle: 'Cinematic widget catalogue',
    icon: Icons.auto_awesome_motion_rounded,
    route: '/premium-showcase',
    tone: Color(0xFFD946EF),
    keywords: ['premium', 'showcase', 'demo'],
  ),
  _Command(
    label: 'Social feed',
    subtitle: 'Travel-aware friend updates',
    icon: Icons.people_alt_rounded,
    route: '/social',
    tone: Color(0xFFF97316),
    keywords: ['social', 'friends', 'feed'],
  ),
  _Command(
    label: 'Timeline',
    subtitle: 'Your journeys over time',
    icon: Icons.timeline_rounded,
    route: '/timeline',
    tone: Color(0xFF14B8A6),
    keywords: ['timeline', 'history', 'memories'],
  ),
  _Command(
    label: 'Analytics',
    subtitle: 'Where your money flows',
    icon: Icons.insights_rounded,
    route: '/analytics',
    tone: Color(0xFFD4AF37),
    keywords: ['analytics', 'spend', 'reports'],
  ),
  _Command(
    label: 'Receipts',
    subtitle: 'Scan + categorise spend',
    icon: Icons.receipt_long_rounded,
    route: '/receipt',
    tone: Color(0xFFF59E0B),
    keywords: ['receipt', 'expense', 'tax'],
  ),
  _Command(
    label: 'Lock',
    subtitle: 'Lock the app & require auth',
    icon: Icons.lock_rounded,
    route: '/lock',
    tone: Color(0xFFE11D48),
    keywords: ['lock', 'logout', 'security'],
  ),
];
