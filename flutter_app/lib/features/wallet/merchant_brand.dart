import 'package:flutter/material.dart';

/// Merchant brand intelligence — resolves a transaction's free-text
/// `merchant` / `description` to a typed brand profile with a tonal
/// accent and a Material icon. Keeps the OS2 wallet ribbon icons
/// looking deliberate and on-brand without changing the visible
/// typography or layout.
///
/// This is intentionally a *directory*, not a network call: it sits
/// inside the app so the wallet ribbon renders deterministically on
/// fresh installs and during offline use. Add new entries here as
/// new merchants appear in demo / API payloads.
class MerchantBrand {
  const MerchantBrand({
    required this.name,
    required this.icon,
    required this.tone,
    this.category,
  });

  final String name;
  final IconData icon;
  final Color tone;
  final String? category;
}

class MerchantDirectory {
  const MerchantDirectory._();

  /// Tonal palette aligned with the OS2 token system. We don't import
  /// `os2_tokens.dart` here so the directory remains a pure data
  /// module that can be exercised in tests without pulling the entire
  /// design system.
  static const _travel = Color(0xFF60A5FA);
  static const _dining = Color(0xFFF59E0B);
  static const _lodging = Color(0xFFD4A574);
  static const _transport = Color(0xFF6366F1);
  static const _activities = Color(0xFFE11D48);
  static const _shopping = Color(0xFF10B981);
  static const _subs = Color(0xFFA855F7);
  static const _insurance = Color(0xFF06B6D4);
  static const _fx = Color(0xFF22C55E);
  static const _other = Color(0xFF94A3B8);

  /// Curated merchant directory. Keys are matched case-insensitively
  /// against the merchant + description; longer keys win.
  static const Map<String, MerchantBrand> _entries = {
    // ───── Airlines
    'united': MerchantBrand(
      name: 'United Airlines',
      icon: Icons.flight_rounded,
      tone: _travel,
      category: 'Travel',
    ),
    'delta': MerchantBrand(
      name: 'Delta',
      icon: Icons.flight_rounded,
      tone: _travel,
      category: 'Travel',
    ),
    'lufthansa': MerchantBrand(
      name: 'Lufthansa',
      icon: Icons.flight_rounded,
      tone: _travel,
      category: 'Travel',
    ),
    'emirates': MerchantBrand(
      name: 'Emirates',
      icon: Icons.flight_rounded,
      tone: _travel,
      category: 'Travel',
    ),
    'qatar airways': MerchantBrand(
      name: 'Qatar Airways',
      icon: Icons.flight_rounded,
      tone: _travel,
      category: 'Travel',
    ),
    'singapore airlines': MerchantBrand(
      name: 'Singapore Airlines',
      icon: Icons.flight_rounded,
      tone: _travel,
      category: 'Travel',
    ),
    'ana': MerchantBrand(
      name: 'ANA',
      icon: Icons.flight_rounded,
      tone: _travel,
      category: 'Travel',
    ),
    'jal': MerchantBrand(
      name: 'JAL',
      icon: Icons.flight_rounded,
      tone: _travel,
      category: 'Travel',
    ),
    'air france': MerchantBrand(
      name: 'Air France',
      icon: Icons.flight_rounded,
      tone: _travel,
      category: 'Travel',
    ),
    'klm': MerchantBrand(
      name: 'KLM',
      icon: Icons.flight_rounded,
      tone: _travel,
      category: 'Travel',
    ),
    'british airways': MerchantBrand(
      name: 'British Airways',
      icon: Icons.flight_rounded,
      tone: _travel,
      category: 'Travel',
    ),
    'virgin atlantic': MerchantBrand(
      name: 'Virgin Atlantic',
      icon: Icons.flight_rounded,
      tone: _travel,
      category: 'Travel',
    ),

    // ───── Lodging
    'aman': MerchantBrand(
      name: 'Aman',
      icon: Icons.hotel_rounded,
      tone: _lodging,
      category: 'Lodging',
    ),
    'aman tokyo': MerchantBrand(
      name: 'Aman Tokyo',
      icon: Icons.hotel_rounded,
      tone: _lodging,
      category: 'Lodging',
    ),
    'hilton': MerchantBrand(
      name: 'Hilton',
      icon: Icons.hotel_rounded,
      tone: _lodging,
      category: 'Lodging',
    ),
    'marriott': MerchantBrand(
      name: 'Marriott',
      icon: Icons.hotel_rounded,
      tone: _lodging,
      category: 'Lodging',
    ),
    'ritz paris': MerchantBrand(
      name: 'Ritz Paris',
      icon: Icons.hotel_rounded,
      tone: _lodging,
      category: 'Lodging',
    ),
    'ritz-carlton': MerchantBrand(
      name: 'Ritz-Carlton',
      icon: Icons.hotel_rounded,
      tone: _lodging,
      category: 'Lodging',
    ),
    'four seasons': MerchantBrand(
      name: 'Four Seasons',
      icon: Icons.hotel_rounded,
      tone: _lodging,
      category: 'Lodging',
    ),
    'airbnb': MerchantBrand(
      name: 'Airbnb',
      icon: Icons.holiday_village_rounded,
      tone: _lodging,
      category: 'Lodging',
    ),
    'booking.com': MerchantBrand(
      name: 'Booking.com',
      icon: Icons.holiday_village_rounded,
      tone: _lodging,
      category: 'Lodging',
    ),

    // ───── Mobility
    'uber': MerchantBrand(
      name: 'Uber',
      icon: Icons.local_taxi_rounded,
      tone: _transport,
      category: 'Transport',
    ),
    'lyft': MerchantBrand(
      name: 'Lyft',
      icon: Icons.local_taxi_rounded,
      tone: _transport,
      category: 'Transport',
    ),
    'jr east': MerchantBrand(
      name: 'JR East',
      icon: Icons.train_rounded,
      tone: _transport,
      category: 'Transport',
    ),
    'metro': MerchantBrand(
      name: 'Metro',
      icon: Icons.directions_subway_rounded,
      tone: _transport,
      category: 'Transport',
    ),

    // ───── Dining
    'sushi saito': MerchantBrand(
      name: 'Sushi Saito',
      icon: Icons.set_meal_rounded,
      tone: _dining,
      category: 'Dining',
    ),
    'le comptoir': MerchantBrand(
      name: 'Le Comptoir',
      icon: Icons.restaurant_rounded,
      tone: _dining,
      category: 'Dining',
    ),
    'starbucks': MerchantBrand(
      name: 'Starbucks',
      icon: Icons.local_cafe_rounded,
      tone: _dining,
      category: 'Dining',
    ),

    // ───── Activities
    'teamlab': MerchantBrand(
      name: 'teamLab',
      icon: Icons.museum_rounded,
      tone: _activities,
      category: 'Activities',
    ),
    'viator': MerchantBrand(
      name: 'Viator',
      icon: Icons.local_activity_rounded,
      tone: _activities,
      category: 'Activities',
    ),
    'getyourguide': MerchantBrand(
      name: 'GetYourGuide',
      icon: Icons.local_activity_rounded,
      tone: _activities,
      category: 'Activities',
    ),

    // ───── Subscriptions
    'apple': MerchantBrand(
      name: 'Apple',
      icon: Icons.apple_rounded,
      tone: _subs,
      category: 'Subscription',
    ),
    'spotify': MerchantBrand(
      name: 'Spotify',
      icon: Icons.music_note_rounded,
      tone: _subs,
      category: 'Subscription',
    ),
    'netflix': MerchantBrand(
      name: 'Netflix',
      icon: Icons.movie_rounded,
      tone: _subs,
      category: 'Subscription',
    ),
    'icloud': MerchantBrand(
      name: 'iCloud+',
      icon: Icons.cloud_rounded,
      tone: _subs,
      category: 'Subscription',
    ),

    // ───── Insurance / FX / Other
    'allianz': MerchantBrand(
      name: 'Allianz',
      icon: Icons.health_and_safety_rounded,
      tone: _insurance,
      category: 'Insurance',
    ),
    'world nomads': MerchantBrand(
      name: 'World Nomads',
      icon: Icons.shield_rounded,
      tone: _insurance,
      category: 'Insurance',
    ),
    'globeid fx': MerchantBrand(
      name: 'GlobeID FX',
      icon: Icons.currency_exchange_rounded,
      tone: _fx,
      category: 'FX',
    ),
  };

  /// Category fallback profiles — used when no specific merchant
  /// matches but the transaction has a known category.
  static const Map<String, MerchantBrand> _categoryFallback = {
    'Travel': MerchantBrand(
      name: 'Travel',
      icon: Icons.flight_rounded,
      tone: _travel,
      category: 'Travel',
    ),
    'Dining': MerchantBrand(
      name: 'Dining',
      icon: Icons.restaurant_rounded,
      tone: _dining,
      category: 'Dining',
    ),
    'Lodging': MerchantBrand(
      name: 'Stay',
      icon: Icons.hotel_rounded,
      tone: _lodging,
      category: 'Lodging',
    ),
    'Transport': MerchantBrand(
      name: 'Transport',
      icon: Icons.directions_car_rounded,
      tone: _transport,
      category: 'Transport',
    ),
    'Activities': MerchantBrand(
      name: 'Activities',
      icon: Icons.local_activity_rounded,
      tone: _activities,
      category: 'Activities',
    ),
    'Shopping': MerchantBrand(
      name: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      tone: _shopping,
      category: 'Shopping',
    ),
    'Subscription': MerchantBrand(
      name: 'Subscription',
      icon: Icons.autorenew_rounded,
      tone: _subs,
      category: 'Subscription',
    ),
    'Insurance': MerchantBrand(
      name: 'Insurance',
      icon: Icons.shield_rounded,
      tone: _insurance,
      category: 'Insurance',
    ),
    'FX': MerchantBrand(
      name: 'Currency exchange',
      icon: Icons.currency_exchange_rounded,
      tone: _fx,
      category: 'FX',
    ),
  };

  static const MerchantBrand _unknown = MerchantBrand(
    name: 'Transaction',
    icon: Icons.payments_rounded,
    tone: _other,
  );

  /// Resolves a merchant / description / category triple to a typed
  /// brand. Longest matching key wins.
  static MerchantBrand resolve({
    String? merchant,
    String? description,
    String? category,
  }) {
    final haystack =
        '${merchant ?? ''} ${description ?? ''}'.trim().toLowerCase();
    if (haystack.isNotEmpty) {
      // Sort keys by length descending so "aman tokyo" beats "aman".
      final keys = _entries.keys.toList()
        ..sort((a, b) => b.length.compareTo(a.length));
      for (final key in keys) {
        if (haystack.contains(key)) return _entries[key]!;
      }
    }
    if (category != null && _categoryFallback.containsKey(category)) {
      return _categoryFallback[category]!;
    }
    return _unknown;
  }
}
