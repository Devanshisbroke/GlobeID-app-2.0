import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/agentic_chip.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/cinematic_hero.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/section_header.dart';

/// PhrasebookScreen — destination-aware phrasebook + live translator.
///
/// Adapts to current trip context. Each phrase has a native + romanised
/// + meaning trio, grouped by intent (greetings, food, transit,
/// emergencies). Tapping a phrase pretends to play TTS via haptics and
/// surfaces the translator dock for free-form lookup.
class PhrasebookScreen extends StatefulWidget {
  const PhrasebookScreen({
    super.key,
    this.locale = 'Japanese',
    this.flag = '🇯🇵',
    this.tone = const Color(0xFFE11D48),
  });

  final String locale;
  final String flag;
  final Color tone;

  @override
  State<PhrasebookScreen> createState() => _PhrasebookScreenState();
}

class _PhrasebookScreenState extends State<PhrasebookScreen> {
  int _category = 0;
  int? _expanded;

  static const _categories = <(IconData, String)>[
    (Icons.waving_hand_rounded, 'Greetings'),
    (Icons.restaurant_rounded, 'Food'),
    (Icons.train_rounded, 'Transit'),
    (Icons.shopping_bag_rounded, 'Shopping'),
    (Icons.emergency_rounded, 'Emergency'),
  ];

  static const _phrases = <List<(String, String, String)>>[
    [
      ('こんにちは', 'Konnichiwa', 'Hello'),
      ('おはようございます', 'Ohayou gozaimasu', 'Good morning'),
      ('こんばんは', 'Konbanwa', 'Good evening'),
      ('ありがとうございます', 'Arigatou gozaimasu', 'Thank you'),
      ('すみません', 'Sumimasen', 'Excuse me / sorry'),
      ('英語を話せますか?', 'Eigo wo hanasemasu ka?', 'Do you speak English?'),
    ],
    [
      ('メニューをください', 'Menyuu wo kudasai', 'Menu, please'),
      ('おすすめは何ですか?', 'Osusume wa nan desu ka?', "What's recommended?"),
      ('美味しいです', 'Oishii desu', 'It is delicious'),
      ('お会計お願いします', 'Okaikei onegai shimasu', 'Check, please'),
      ('辛くないですか?', 'Karakunai desu ka?', 'Is it not spicy?'),
    ],
    [
      ('駅はどこですか?', 'Eki wa doko desu ka?', 'Where is the station?'),
      ('切符を一枚ください', 'Kippu wo ichimai kudasai', 'One ticket, please'),
      ('次の電車は何時ですか?', 'Tsugi no densha wa nanji desu ka?',
          'When is the next train?'),
      ('降ります', 'Orimasu', 'I am getting off'),
    ],
    [
      ('いくらですか?', 'Ikura desu ka?', 'How much is it?'),
      ('クレジットカードは使えますか?', 'Kurejitto kaado wa tsukaemasu ka?',
          'Do you accept credit card?'),
      ('袋はいりません', 'Fukuro wa irimasen', 'I do not need a bag'),
    ],
    [
      ('助けてください', 'Tasukete kudasai', 'Please help me'),
      ('警察を呼んでください', 'Keisatsu wo yonde kudasai', 'Please call the police'),
      ('救急車を呼んでください', 'Kyuukyuusha wo yonde kudasai',
          'Please call an ambulance'),
      ('英語の通訳が必要です', 'Eigo no tsuuyaku ga hitsuyou desu',
          'I need an English interpreter'),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phrases = _phrases[_category];

    return PageScaffold(
      title: 'Phrasebook',
      subtitle: '${widget.flag} ${widget.locale} · adapted to your trip',
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          AnimatedAppearance(
            child: CinematicHero(
              eyebrow: 'LIVE PHRASEBOOK',
              title: '${widget.locale} for travellers',
              subtitle:
                  'Hand-picked phrases your destination will actually need.',
              flag: widget.flag,
              tone: widget.tone,
              icon: Icons.translate_rounded,
              badges: const [
                HeroBadge(label: '160+ phrases', icon: Icons.menu_book_rounded),
                HeroBadge(
                    label: 'Voice ready', icon: Icons.record_voice_over_rounded),
                HeroBadge(label: 'Offline', icon: Icons.cloud_off_rounded),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          AnimatedAppearance(
            delay: const Duration(milliseconds: 60),
            child: PremiumCard(
              padding: const EdgeInsets.all(AppTokens.space3),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.tone.withValues(alpha: 0.18),
                    ),
                    child: Icon(Icons.mic_rounded,
                        color: widget.tone, size: 20),
                  ),
                  const SizedBox(width: AppTokens.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hold to speak any phrase',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            )),
                        Text(
                          'Translates between English ↔ ${widget.locale}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.graphic_eq_rounded,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _categories.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppTokens.space2),
              itemBuilder: (_, i) {
                final selected = i == _category;
                final cat = _categories[i];
                return Pressable(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _category = i;
                      _expanded = null;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? widget.tone.withValues(alpha: 0.18)
                          : theme.colorScheme.surface,
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusFull),
                      border: Border.all(
                        color: selected
                            ? widget.tone
                            : theme.colorScheme.outline
                                .withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.$1,
                            size: 14,
                            color: selected
                                ? widget.tone
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Text(
                          cat.$2,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? widget.tone
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          for (var i = 0; i < phrases.length; i++)
            AnimatedAppearance(
              delay: Duration(milliseconds: 40 * i),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.space2),
                child: _PhraseTile(
                  phrase: phrases[i],
                  expanded: _expanded == i,
                  tone: widget.tone,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _expanded = _expanded == i ? null : i);
                  },
                ),
              ),
            ),
          const SizedBox(height: AppTokens.space4),
          const SectionHeader(
              title: 'Quick chains',
              subtitle: 'What people usually do next from here'),
          AgenticBand(
            title: '',
            chips: [
              AgenticChip(
                icon: Icons.local_taxi_rounded,
                label: 'Hail a taxi',
                eyebrow: 'transit',
                route: '/services/rides',
                tone: const Color(0xFFEA580C),
              ),
              AgenticChip(
                icon: Icons.restaurant_rounded,
                label: 'Order food',
                eyebrow: 'food',
                route: '/services/food',
                tone: const Color(0xFFD97706),
              ),
              AgenticChip(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan to pay',
                eyebrow: 'wallet',
                route: '/wallet/scan',
                tone: const Color(0xFF10B981),
              ),
              AgenticChip(
                icon: Icons.emergency_rounded,
                label: 'Emergency help',
                eyebrow: 'safety',
                route: '/emergency',
                tone: const Color(0xFFDC2626),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          CinematicButton(
            label: 'Open live translator',
            icon: Icons.translate_rounded,
            gradient: LinearGradient(
              colors: [widget.tone, widget.tone.withValues(alpha: 0.55)],
            ),
            onPressed: () {
              HapticFeedback.heavyImpact();
              GoRouter.of(context).push('/copilot');
            },
          ),
          const SizedBox(height: AppTokens.space9),
        ],
      ),
    );
  }
}

class _PhraseTile extends StatelessWidget {
  const _PhraseTile({
    required this.phrase,
    required this.expanded,
    required this.tone,
    required this.onTap,
  });
  final (String, String, String) phrase;
  final bool expanded;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onTap: onTap,
      child: PremiumCard(
        padding: const EdgeInsets.all(AppTokens.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tone.withValues(alpha: 0.18),
                  ),
                  child: Icon(Icons.volume_up_rounded, color: tone, size: 16),
                ),
                const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(phrase.$1,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: tone,
                          )),
                      Text(phrase.$2,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                            fontStyle: FontStyle.italic,
                          )),
                    ],
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 220),
                  turns: expanded ? 0.5 : 0,
                  child: Icon(Icons.expand_more_rounded,
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.5)),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppTokens.space3),
                      child: Container(
                        padding: const EdgeInsets.all(AppTokens.space3),
                        decoration: BoxDecoration(
                          color: tone.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusLg),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.subdirectory_arrow_right_rounded,
                                color: tone, size: 16),
                            const SizedBox(width: AppTokens.space2),
                            Expanded(
                              child: Text(phrase.$3,
                                  style:
                                      theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                            Icon(Icons.bookmark_outline_rounded,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                                size: 18),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
