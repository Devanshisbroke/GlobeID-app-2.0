import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_tokens.dart';
import '../../widgets/agentic_chip.dart';
import '../../widgets/animated_appearance.dart';
import '../../widgets/cinematic_button.dart';
import '../../widgets/cinematic_hero.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/premium/premium.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/pressable.dart';
import '../../widgets/section_header.dart';

/// Cinematic restaurant detail page — opened from the Food list.
///
/// Sections:
///   • Cinematic hero (cuisine, rating, walking distance)
///   • Mode toggle (Dine-in vs Delivery)
///   • Featured dish carousel
///   • Menu (sectioned, 3 categories)
///   • Reviews
///   • Reservation footer
///
/// Route args carrier — passed via go_router `extra` so we can deep-link
/// `/services/food/detail` from the bespoke food list without losing the
/// per-item context (tonality, cuisine, flag, price tier).
class RestaurantDetailArgs {
  const RestaurantDetailArgs({
    required this.name,
    required this.cuisine,
    required this.city,
    required this.rating,
    required this.tonality,
    required this.flag,
    required this.priceTier,
  });

  final String name;
  final String cuisine;
  final String city;
  final double rating;
  final Color tonality;
  final String flag;
  final int priceTier;
}

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({
    super.key,
    required this.name,
    required this.cuisine,
    required this.city,
    required this.rating,
    required this.tonality,
    required this.flag,
    required this.priceTier,
  });

  final String name;
  final String cuisine;
  final String city;
  final double rating;
  final Color tonality;
  final String flag;
  final int priceTier;

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  bool _delivery = false;
  final Set<String> _picks = <String>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _menu
        .expand((c) => c.items)
        .where((d) => _picks.contains(d.name))
        .fold<double>(0, (a, b) => a + b.price);
    return PageScaffold(
      title: widget.name,
      subtitle: '${widget.flag} ${widget.city} · ${widget.cuisine}',
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: AnimatedAppearance(
                  child: CinematicReveal(
                    tone: widget.tonality,
                    child: Stack(
                      children: [
                        CinematicHero(
                          eyebrow:
                              '${widget.rating.toStringAsFixed(1)}★ · ${widget.cuisine.toUpperCase()}',
                          title: widget.name,
                          subtitle:
                              '${widget.city} · ${'\$' * widget.priceTier} · open until 23:30',
                          icon: Icons.restaurant_rounded,
                          flag: widget.flag,
                          tone: widget.tonality,
                          badges: const [
                            HeroBadge(
                                label: 'Tonight 19:30',
                                icon: Icons.event_rounded),
                            HeroBadge(
                                label: '4 min walk',
                                icon: Icons.directions_walk_rounded),
                            HeroBadge(
                                label: 'Free wine pairing',
                                icon: Icons.local_bar_rounded),
                          ],
                        ),
                        Positioned(
                          top: AppTokens.space3,
                          right: AppTokens.space3,
                          child: PremiumHud(
                            label: _delivery ? 'DELIVERY' : 'DINE-IN',
                            tone: widget.tonality,
                            trailing: Text(
                              widget.flag,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                  child: SizedBox(height: AppTokens.space3)),
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppTokens.space5),
                sliver: SliverToBoxAdapter(
                  child: PremiumInfoRail(
                    tiles: [
                      InfoRailTile(
                        icon: Icons.star_rounded,
                        label: 'Rating',
                        value: widget.rating.toStringAsFixed(1),
                        tone: const Color(0xFFEAB308),
                      ),
                      InfoRailTile(
                        icon: Icons.attach_money_rounded,
                        label: 'Tier',
                        value: '\$' * widget.priceTier,
                        tone: const Color(0xFF10B981),
                      ),
                      InfoRailTile(
                        icon: Icons.schedule_rounded,
                        label: 'Open',
                        value: 'Til 23:30',
                        tone: const Color(0xFF6366F1),
                      ),
                      InfoRailTile(
                        icon: Icons.directions_walk_rounded,
                        label: 'Distance',
                        value: '4 min',
                        tone: const Color(0xFFEA580C),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                  child: SizedBox(height: AppTokens.space3)),
              SliverToBoxAdapter(
                child: _ModeToggle(
                  delivery: _delivery,
                  tone: widget.tonality,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    setState(() => _delivery = v);
                  },
                ),
              ),
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: "Chef's specials",
                  subtitle: 'Tap to add',
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 184,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    itemCount: _featured.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppTokens.space3),
                    itemBuilder: (_, i) => _FeaturedDish(
                      dish: _featured[i],
                      tone: widget.tonality,
                      selected: _picks.contains(_featured[i].name),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (_picks.contains(_featured[i].name)) {
                            _picks.remove(_featured[i].name);
                          } else {
                            _picks.add(_featured[i].name);
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
              for (final cat in _menu) ...[
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: cat.title,
                    subtitle: cat.subtitle,
                  ),
                ),
                SliverList.separated(
                  itemCount: cat.items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppTokens.space2),
                  itemBuilder: (_, i) {
                    final dish = cat.items[i];
                    final selected = _picks.contains(dish.name);
                    return Pressable(
                      scale: 0.985,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (selected) {
                            _picks.remove(dish.name);
                          } else {
                            _picks.add(dish.name);
                          }
                        });
                      },
                      child: PremiumCard(
                        padding: const EdgeInsets.all(AppTokens.space4),
                        borderColor: selected
                            ? widget.tonality.withValues(alpha: 0.5)
                            : null,
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected
                                    ? widget.tonality
                                    : widget.tonality.withValues(alpha: 0.16),
                              ),
                              child: Icon(
                                selected
                                    ? Icons.check_rounded
                                    : Icons.add_rounded,
                                size: 14,
                                color:
                                    selected ? Colors.white : widget.tonality,
                              ),
                            ),
                            const SizedBox(width: AppTokens.space3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(dish.name,
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      )),
                                  Text(dish.notes,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.7),
                                      )),
                                ],
                              ),
                            ),
                            Text(
                              '\$${dish.price.toStringAsFixed(0)}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: widget.tonality,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Recent reviews',
                  subtitle: 'From verified diners',
                ),
              ),
              SliverList.separated(
                itemCount: _reviews.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppTokens.space2),
                itemBuilder: (_, i) {
                  final r = _reviews[i];
                  return PremiumCard(
                    padding: const EdgeInsets.all(AppTokens.space4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor:
                                  widget.tonality.withValues(alpha: 0.18),
                              child: Text(r.flag,
                                  style: const TextStyle(fontSize: 14)),
                            ),
                            const SizedBox(width: AppTokens.space2),
                            Text(r.author,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                )),
                            const Spacer(),
                            Icon(Icons.star_rounded,
                                color: const Color(0xFFD97706), size: 16),
                            Text(' ${r.score}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                )),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('"${r.quote}"',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            )),
                      ],
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Around the table',
                  subtitle: 'GlobeID can chain these for you',
                ),
              ),
              SliverToBoxAdapter(
                child: AgenticBand(
                  title: 'After dinner',
                  chips: [
                    AgenticChip(
                      icon: Icons.local_taxi_rounded,
                      label: 'Ride home',
                      route: '/services/rides',
                      tone: const Color(0xFFEA580C),
                    ),
                    AgenticChip(
                      icon: Icons.local_bar_rounded,
                      label: 'Cocktail bar nearby',
                      tone: const Color(0xFF7E22CE),
                    ),
                    AgenticChip(
                      icon: Icons.museum_rounded,
                      label: 'Late-night gallery',
                      tone: theme.colorScheme.primary,
                    ),
                    AgenticChip(
                      icon: Icons.translate_rounded,
                      label: 'Allergens · ${widget.cuisine}',
                      route: '/copilot',
                      tone: const Color(0xFF6366F1),
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(
                  AppTokens.space5,
                  AppTokens.space3,
                  AppTokens.space5,
                  AppTokens.space5,
                ),
                child: PremiumCard(
                  padding: const EdgeInsets.all(AppTokens.space4),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _delivery
                                ? 'Delivery total'
                                : '${_picks.length} items',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(0)}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: widget.tonality,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 196,
                        child: CinematicButton(
                          label: _delivery ? 'Order delivery' : 'Reserve table',
                          icon: _delivery
                              ? Icons.delivery_dining_rounded
                              : Icons.event_seat_rounded,
                          gradient: LinearGradient(
                            colors: [
                              widget.tonality,
                              widget.tonality.withValues(alpha: 0.6),
                            ],
                          ),
                          onPressed: () {
                            HapticFeedback.heavyImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: widget.tonality,
                                content: Text(
                                  _delivery
                                      ? 'Delivery placed · ${widget.name}'
                                      : 'Table held · ${widget.name} 19:30',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _featured = <_Dish>[
    _Dish(
        name: "Chef's omakase",
        notes: '12-course tasting',
        price: 280,
        icon: Icons.restaurant_menu_rounded),
    _Dish(
        name: 'Wagyu carpaccio',
        notes: 'A5 · truffle · sesame',
        price: 64,
        icon: Icons.lunch_dining_rounded),
    _Dish(
        name: 'Otoro nigiri',
        notes: 'Bluefin · 6 pieces',
        price: 88,
        icon: Icons.set_meal_rounded),
    _Dish(
        name: 'Black truffle tagliatelle',
        notes: 'Hand-rolled · seasonal',
        price: 56,
        icon: Icons.dinner_dining_rounded),
  ];

  static final _menu = <_MenuCategory>[
    _MenuCategory(
      title: 'Starters',
      subtitle: 'To share',
      items: const [
        _Dish(
            name: 'Edamame',
            notes: 'Smoked salt · chili',
            price: 12,
            icon: Icons.eco_rounded),
        _Dish(
            name: 'Hamachi crudo',
            notes: 'Yellowtail · ponzu · jalapeño',
            price: 32,
            icon: Icons.set_meal_rounded),
        _Dish(
            name: 'Seared foie gras',
            notes: 'Pear compote · brioche',
            price: 38,
            icon: Icons.dinner_dining_rounded),
      ],
    ),
    _MenuCategory(
      title: 'Mains',
      subtitle: 'Hand-picked',
      items: const [
        _Dish(
            name: 'Wagyu A5 ribeye',
            notes: '8oz · sea salt · wasabi',
            price: 180,
            icon: Icons.lunch_dining_rounded),
        _Dish(
            name: 'Black cod miso',
            notes: 'Sake-glazed · 72hr marinade',
            price: 78,
            icon: Icons.set_meal_rounded),
        _Dish(
            name: 'Truffle risotto',
            notes: 'Carnaroli · 36-month parmesan',
            price: 64,
            icon: Icons.dinner_dining_rounded),
      ],
    ),
    _MenuCategory(
      title: 'Desserts',
      subtitle: 'Save room',
      items: const [
        _Dish(
            name: 'Yuzu sorbet',
            notes: 'Champagne float',
            price: 22,
            icon: Icons.icecream_rounded),
        _Dish(
            name: 'Matcha tiramisu',
            notes: 'Layered · mascarpone',
            price: 26,
            icon: Icons.cake_rounded),
      ],
    ),
  ];

  static const _reviews = <_FoodReview>[
    _FoodReview(
        author: 'Lina K.',
        flag: '🇸🇪',
        score: 4.9,
        quote:
            'Service was almost telepathic — they knew when to refill, when to disappear.'),
    _FoodReview(
        author: 'James W.',
        flag: '🇬🇧',
        score: 4.8,
        quote:
            'Wagyu is now a memory I will chase for years. Incredible mineral finish.'),
    _FoodReview(
        author: 'Akira S.',
        flag: '🇯🇵',
        score: 4.7,
        quote:
            'Best omakase outside of Tsukiji. The chef pairs sakes like wine — it elevates everything.'),
  ];
}

class _Dish {
  const _Dish({
    required this.name,
    required this.notes,
    required this.price,
    required this.icon,
  });
  final String name;
  final String notes;
  final double price;
  final IconData icon;
}

class _MenuCategory {
  const _MenuCategory({
    required this.title,
    required this.subtitle,
    required this.items,
  });
  final String title;
  final String subtitle;
  final List<_Dish> items;
}

class _FoodReview {
  const _FoodReview({
    required this.author,
    required this.flag,
    required this.score,
    required this.quote,
  });
  final String author;
  final String flag;
  final double score;
  final String quote;
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.delivery,
    required this.tone,
    required this.onChanged,
  });
  final bool delivery;
  final Color tone;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _ToggleSegment(
              label: 'Dine-in',
              icon: Icons.event_seat_rounded,
              active: !delivery,
              tone: tone,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _ToggleSegment(
              label: 'Delivery',
              icon: Icons.delivery_dining_rounded,
              active: delivery,
              tone: tone,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.label,
    required this.icon,
    required this.active,
    required this.tone,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final Color tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.97,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationSm,
        curve: AppTokens.easeOutSoft,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius2xl),
          gradient: active
              ? LinearGradient(
                  colors: [tone, tone.withValues(alpha: 0.55)],
                )
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: active
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 6),
            Text(label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: active
                      ? Colors.white
                      : theme.colorScheme.onSurface.withValues(alpha: 0.78),
                )),
          ],
        ),
      ),
    );
  }
}

class _FeaturedDish extends StatelessWidget {
  const _FeaturedDish({
    required this.dish,
    required this.tone,
    required this.selected,
    required this.onTap,
  });
  final _Dish dish;
  final Color tone;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      scale: 0.96,
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTokens.durationSm,
        width: 188,
        padding: const EdgeInsets.all(AppTokens.space3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius2xl),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: selected
                ? [tone, tone.withValues(alpha: 0.45)]
                : [
                    tone.withValues(alpha: 0.85),
                    tone.withValues(alpha: 0.30),
                  ],
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: tone.withValues(alpha: 0.40),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.22),
              ),
              child: Icon(dish.icon, color: Colors.white, size: 18),
            ),
            const Spacer(),
            Text(dish.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  height: 1.1,
                )),
            const SizedBox(height: 2),
            Text(dish.notes,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTokens.radiusFull),
                color: Colors.white.withValues(alpha: 0.20),
              ),
              child: Text(
                '\$${dish.price.toStringAsFixed(0)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
