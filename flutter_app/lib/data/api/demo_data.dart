/// DemoData — realistic offline seed data for every backend endpoint.
///
/// Used by [ApiClient] as a graceful fallback when the real Hono backend
/// is unavailable (no host, timeout, 5xx, etc.). Every payload here is
/// returned wrapped in the canonical `{ ok: true, data: <payload> }`
/// envelope, matching the on-the-wire shape the rest of the app expects.
///
/// Keep this file dependency-free (pure data + small helpers) so it can
/// be loaded eagerly with no I/O.
library;

class DemoData {
  DemoData._();

  /// Returns a JSON-shaped response (the inner `data` value) for the given
  /// HTTP [method] and request [path], or `null` if no demo data is
  /// available for that endpoint.
  ///
  /// [path] is a backend-relative path like `/wallet`, `/trips`, or
  /// `/exchange/rates?base=USD` — query strings are tolerated.
  static dynamic respond(String method, String path) {
    final p = path.split('?').first;

    switch (p) {
      case '/auth/demo':
        return {'token': 'demo-offline-token'};

      case '/user':
        return _user;

      case '/trips':
        return _trips;

      case '/user/documents':
        return _documents;

      case '/insights/travel':
        return _travelInsights;
      case '/insights/wallet':
        return _walletInsights;
      case '/insights/activity':
        return _activityInsights;

      case '/recommendations':
        return _recommendations;

      case '/alerts':
        return _alerts;

      case '/copilot/respond':
        return {
          'ok': true,
          'message': "Here's what I'm seeing across your trips and wallet.",
          'suggestions': const [
            'Show me my next trip',
            'Convert 100 USD to EUR',
            "What's my carbon footprint?",
          ],
        };
      case '/copilot/history':
        return _copilotHistory;

      case '/planner/trips':
        return _plannerTrips;

      case '/context/current':
        return _context;

      case '/lifecycle/trips':
        return _lifecycleTrips;

      case '/wallet':
        return _wallet;

      case '/wallet/transactions':
        return {'ok': true};
      case '/wallet/convert':
        return {'ok': true, 'rate': 0.92, 'amount': 92.00};
      case '/wallet/state':
        return {'ok': true};

      case '/loyalty':
        return _loyalty;
      case '/loyalty/earn':
      case '/loyalty/redeem':
        return {'ok': true};

      case '/safety/contacts':
        return _safetyContacts;

      case '/score':
        return _score;

      case '/budget':
        return _budget;

      case '/budget/caps':
        return {'ok': true};

      case '/fraud/findings':
        return _fraud;
      case '/fraud/scan':
        return _fraud;

      case '/exchange/rates':
        return _exchangeRates;
      case '/exchange/quote':
        return _exchangeRates;

      case '/visa/policies':
        return _visaPolicies;
      case '/visa/policy':
        return _visaPolicy;

      case '/insurance/plans':
        return _insurancePlans;
      case '/insurance/quote':
        return {'amount': 48.50, 'currency': 'USD'};

      case '/esim/plans':
        return _esimPlans;

      case '/hotels/search':
        return _hotels;
      case '/food/restaurants':
        return _food;
      case '/rides/search':
        return _rides;
      case '/local/services':
        return _localServices;
    }

    // Path-prefix matches (e.g. /lifecycle/flights/:id, /weather/forecast)
    if (p.startsWith('/lifecycle/flights/')) {
      return _flightStatus;
    }
    if (p.startsWith('/weather/forecast')) {
      return _weather;
    }
    if (p.startsWith('/hotels/')) {
      return _hotels['items']?.first;
    }
    if (p.startsWith('/planner/trips/')) {
      return {'ok': true};
    }
    if (p.startsWith('/safety/contacts/')) {
      return {'ok': true};
    }
    if (p.startsWith('/alerts/')) {
      return {'ok': true};
    }
    if (p.startsWith('/trips/')) {
      return {'ok': true};
    }
    if (p == '/copilot/history' && method == 'DELETE') {
      return {'ok': true};
    }

    return null;
  }

  // ─────────────────── public typed seed accessors ────────────────────
  //
  // Used by Riverpod Notifier.build() callbacks to populate state
  // synchronously on a fresh install (before async hydrate() resolves).
  // This guarantees every flagship surface is alive on first paint —
  // no blank Travel tab, no $0.00 Treasury, no missing DEPARTURE card.
  //
  // The maps are deep-copied via JSON encode/decode round-trips inside
  // the callers' fromJson constructors, so mutations to returned
  // collections never poison the const seeds.

  static Map<String, dynamic> seedUser() => _user;
  static List<Map<String, dynamic>> seedTrips() => _trips;
  static List<Map<String, dynamic>> seedDocuments() => _documents;
  static Map<String, dynamic> seedWallet() => _wallet;
  static List<Map<String, dynamic>> seedLifecycleTrips() => _lifecycleTrips;

  // ─────────────────── seed data ───────────────────

  static const Map<String, dynamic> _user = {
    'userId': 'usr-globeid-001',
    'name': 'Devansh Barai',
    'passportNumber': 'P1234567',
    'nationality': 'India',
    'nationalityFlag': '🇮🇳',
    'verifiedStatus': 'verified',
    'avatarUrl': '',
    'email': 'devansh@globeid.app',
    'memberSince': '2023-04-12',
    'identityScore': 826,
  };

  static const List<Map<String, dynamic>> _trips = [
    {
      'id': 'trp-001',
      'from': 'SFO',
      'to': 'NRT',
      'date': '2026-06-12',
      'airline': 'United',
      'duration': '11h 05m',
      'type': 'upcoming',
      'flightNumber': 'UA837',
      'source': 'history',
    },
    {
      'id': 'trp-002',
      'from': 'NRT',
      'to': 'CDG',
      'date': '2026-06-19',
      'airline': 'Air France',
      'duration': '12h 40m',
      'type': 'upcoming',
      'flightNumber': 'AF273',
      'source': 'history',
    },
    {
      'id': 'trp-003',
      'from': 'CDG',
      'to': 'JFK',
      'date': '2026-06-30',
      'airline': 'Delta',
      'duration': '8h 20m',
      'type': 'upcoming',
      'flightNumber': 'DL263',
      'source': 'history',
    },
    {
      'id': 'trp-101',
      'from': 'BOM',
      'to': 'DXB',
      'date': '2025-11-04',
      'airline': 'Emirates',
      'duration': '3h 15m',
      'type': 'past',
      'flightNumber': 'EK509',
      'source': 'history',
    },
    {
      'id': 'trp-102',
      'from': 'DXB',
      'to': 'LHR',
      'date': '2025-09-22',
      'airline': 'British Airways',
      'duration': '7h 45m',
      'type': 'past',
      'flightNumber': 'BA106',
      'source': 'history',
    },
    {
      'id': 'trp-103',
      'from': 'LHR',
      'to': 'SFO',
      'date': '2025-08-14',
      'airline': 'Virgin Atlantic',
      'duration': '11h 20m',
      'type': 'past',
      'flightNumber': 'VS19',
      'source': 'history',
    },
  ];

  static const List<Map<String, dynamic>> _documents = [
    {
      'id': 'doc-passport',
      'type': 'passport',
      'label': 'Indian Passport',
      'country': 'India',
      'countryFlag': '🇮🇳',
      'number': 'P1234567',
      'issueDate': '2020-04-12',
      'expiryDate': '2030-04-12',
      'status': 'active',
    },
    {
      'id': 'doc-jp-visa',
      'type': 'visa',
      'label': 'Japan Tourist Visa',
      'country': 'Japan',
      'countryFlag': '🇯🇵',
      'number': 'JP-V-77123',
      'issueDate': '2026-05-01',
      'expiryDate': '2026-08-01',
      'status': 'active',
      'tripId': 'trp-001',
    },
    {
      'id': 'doc-fr-visa',
      'type': 'visa',
      'label': 'Schengen Visa',
      'country': 'France',
      'countryFlag': '🇫🇷',
      'number': 'FR-S-44290',
      'issueDate': '2026-05-15',
      'expiryDate': '2026-09-15',
      'status': 'active',
      'tripId': 'trp-002',
    },
    {
      'id': 'doc-bp-ua837',
      'type': 'boarding_pass',
      'label': 'UA837 SFO → NRT',
      'country': 'United States',
      'countryFlag': '🇺🇸',
      'number': 'UA837-12A',
      'issueDate': '2026-06-12',
      'expiryDate': '2026-06-12',
      'status': 'active',
      'tripId': 'trp-001',
      'legId': 'leg-ua837',
    },
    {
      'id': 'doc-insurance',
      'type': 'travel_insurance',
      'label': 'Allianz Global',
      'country': 'Worldwide',
      'countryFlag': '🌍',
      'number': 'AZ-9988-2026',
      'issueDate': '2026-06-01',
      'expiryDate': '2026-07-31',
      'status': 'active',
    },
  ];

  static const Map<String, dynamic> _travelInsights = {
    'totalDistance': 84210,
    'countries': 18,
    'continents': 5,
    'topRoutes': [
      {'from': 'SFO', 'to': 'JFK', 'count': 8},
      {'from': 'LHR', 'to': 'JFK', 'count': 6},
      {'from': 'BOM', 'to': 'DXB', 'count': 5},
      {'from': 'NRT', 'to': 'CDG', 'count': 3},
    ],
    'carbonKg': 12480,
    'streakDays': 26,
  };

  static const Map<String, dynamic> _walletInsights = {
    'spendByCategory': [
      {'category': 'Travel', 'amount': 4180.20},
      {'category': 'Dining', 'amount': 980.50},
      {'category': 'Lodging', 'amount': 2640.00},
      {'category': 'Transport', 'amount': 412.75},
      {'category': 'Shopping', 'amount': 318.00},
      {'category': 'Other', 'amount': 144.30},
    ],
    'runwayDays': 92,
    'monthlyAverage': 3120.00,
    'last30Days': 2845.00,
  };

  static const Map<String, dynamic> _activityInsights = {
    'items': [
      {
        'title': 'Boarding pass added',
        'subtitle': 'UA837 · SFO → NRT · 12 Jun',
        'type': 'wallet',
      },
      {
        'title': 'Schengen visa verified',
        'subtitle': 'France · valid until 15 Sep 2026',
        'type': 'identity',
      },
      {
        'title': 'Receipt scanned',
        'subtitle': 'Sushi Saito · ¥18,400',
        'type': 'scanner',
      },
      {
        'title': 'FX conversion',
        'subtitle': 'USD 500 → EUR 462.40 @ 0.9248',
        'type': 'wallet',
      },
      {
        'title': 'Trip planned',
        'subtitle': 'Tokyo · 7 days · 12 Jun',
        'type': 'planner',
      },
      {
        'title': 'eSIM activated',
        'subtitle': 'Japan · 5 GB / 15 days',
        'type': 'service',
      },
      {
        'title': 'Identity score +12',
        'subtitle': 'Now Citizen tier · 826',
        'type': 'identity',
      },
    ],
  };

  static const Map<String, dynamic> _recommendations = {
    'items': [
      {
        'title': 'Sushi Saito',
        'subtitle': '★ 4.9 · Tokyo · 3-Michelin · 2 km from your hotel',
        'kind': 'food',
        'flag': '🇯🇵',
      },
      {
        'title': 'Aman Tokyo',
        'subtitle': 'Junisō pool · 33rd floor suite · breakfast incl.',
        'kind': 'hotel',
        'flag': '🇯🇵',
      },
      {
        'title': 'TeamLab Borderless',
        'subtitle': 'Toyosu · digital art · book ahead',
        'kind': 'activity',
        'flag': '🇯🇵',
      },
      {
        'title': 'Mt. Fuji day trip',
        'subtitle': 'Hakone region · onsen + sightseeing',
        'kind': 'activity',
        'flag': '🇯🇵',
      },
      {
        'title': 'Le Comptoir du Relais',
        'subtitle': '★ 4.7 · Paris 6e · classic bistro',
        'kind': 'food',
        'flag': '🇫🇷',
      },
      {
        'title': 'Ritz Paris',
        'subtitle': 'Place Vendôme · suite Coco Chanel · spa',
        'kind': 'hotel',
        'flag': '🇫🇷',
      },
      {
        'title': 'Musée d\'Orsay',
        'subtitle': 'Impressionist masterpieces · skip the line',
        'kind': 'place',
        'flag': '🇫🇷',
      },
    ],
  };

  static const List<Map<String, dynamic>> _alerts = [
    {
      'id': 'alert-001',
      'severity': 'info',
      'title': 'Gate change',
      'message': 'UA837 now departs from gate 78A.',
      'createdAt': '2026-06-12T07:14:00Z',
    },
    {
      'id': 'alert-002',
      'severity': 'success',
      'title': 'Visa approved',
      'message': 'Schengen visa for France is now active.',
      'createdAt': '2026-05-15T10:42:00Z',
    },
    {
      'id': 'alert-003',
      'severity': 'warning',
      'title': 'Carry-on limit',
      'message': 'AF273 enforces 8 kg carry-on. Repack heavy items.',
      'createdAt': '2026-06-18T22:00:00Z',
    },
  ];

  static const List<Map<String, dynamic>> _copilotHistory = [
    {
      'id': 'msg-1',
      'role': 'user',
      'content': 'When does my next flight board?',
      'createdAt': '2026-06-11T08:01:00Z',
    },
    {
      'id': 'msg-2',
      'role': 'assistant',
      'content':
          'UA837 boards at 09:25 from gate 78A · SFO terminal 3. You should leave home by 06:30 to clear TSA.',
      'createdAt': '2026-06-11T08:01:02Z',
    },
    {
      'id': 'msg-3',
      'role': 'user',
      'content': "What's the weather like in Tokyo?",
      'createdAt': '2026-06-11T08:02:11Z',
    },
    {
      'id': 'msg-4',
      'role': 'assistant',
      'content':
          'Tokyo is 27°C and partly cloudy. Light rain Friday — pack a compact umbrella.',
      'createdAt': '2026-06-11T08:02:13Z',
    },
  ];

  static const List<Map<String, dynamic>> _plannerTrips = [
    {
      'id': 'plan-001',
      'title': 'Tokyo · cherry blossom rerun',
      'subtitle': '7 days · 12–19 Jun · 2 cities',
      'pinned': true,
      'budget': 4200,
      'currency': 'USD',
    },
    {
      'id': 'plan-002',
      'title': 'Paris · summer escape',
      'subtitle': '11 days · 19–30 Jun · Schengen',
      'pinned': false,
      'budget': 5800,
      'currency': 'USD',
    },
    {
      'id': 'plan-003',
      'title': 'New York · friends',
      'subtitle': '5 days · 30 Jun – 5 Jul',
      'pinned': false,
      'budget': 2400,
      'currency': 'USD',
    },
    {
      'id': 'plan-004',
      'title': 'Bali · long weekend',
      'subtitle': '4 days · TBD',
      'pinned': false,
      'budget': 1800,
      'currency': 'USD',
    },
  ];

  static const Map<String, dynamic> _context = {
    'location': 'San Francisco, US',
    'localTime': '08:14 PT',
    'weather': '17°C · partly cloudy',
    'nextLeg': 'UA837 · SFO → NRT · departs in 27 h',
    'walletAlert': 'Runway 92 days at current spend',
    'fxAlert': 'USD ↔ JPY 156.42 (-0.4 % week)',
    'safety': 'Low-risk · standard advisories',
    'visa': 'Japan eVisa active · valid 15 May → 15 Aug',
  };

  static const List<Map<String, dynamic>> _lifecycleTrips = [
    {
      'id': 'trp-001',
      'name': 'Tokyo · cherry blossom rerun',
      'stage': 'upcoming',
      'startDate': '2026-06-12',
      'endDate': '2026-06-19',
      'budget': 4200,
      'legs': [
        {
          'id': 'leg-ua837',
          'from': 'SFO',
          'to': 'NRT',
          'airline': 'United',
          'flightNumber': 'UA837',
          'scheduled': '2026-06-12T11:25:00Z',
          'gate': '78A',
          'terminal': '3',
          'seat': '12A',
          'boarding': '2026-06-12T10:50:00Z',
        },
      ],
    },
    {
      'id': 'trp-002',
      'name': 'Paris · summer escape',
      'stage': 'upcoming',
      'startDate': '2026-06-19',
      'endDate': '2026-06-30',
      'budget': 5800,
      'legs': [
        {
          'id': 'leg-af273',
          'from': 'NRT',
          'to': 'CDG',
          'airline': 'Air France',
          'flightNumber': 'AF273',
          'scheduled': '2026-06-19T22:30:00Z',
          'gate': '46',
          'terminal': '1',
          'seat': '7C',
          'boarding': '2026-06-19T21:50:00Z',
        },
      ],
    },
    {
      'id': 'trp-101',
      'name': 'Dubai · stopover',
      'stage': 'past',
      'startDate': '2025-11-04',
      'endDate': '2025-11-08',
      'budget': 1200,
      'legs': [
        {
          'id': 'leg-ek509',
          'from': 'BOM',
          'to': 'DXB',
          'airline': 'Emirates',
          'flightNumber': 'EK509',
          'scheduled': '2025-11-04T03:30:00Z',
          'gate': 'C42',
          'terminal': '2',
          'seat': '14A',
          'boarding': '2025-11-04T02:50:00Z',
        },
      ],
    },
  ];

  static const Map<String, dynamic> _flightStatus = {
    'status': 'on-time',
    'gate': '78A',
    'terminal': '3',
    'departureDelay': 0,
    'arrivalDelay': 0,
    'aircraft': 'Boeing 777-300ER',
  };

  static const Map<String, dynamic> _wallet = {
    'balances': [
      {
        'currency': 'USD',
        'symbol': '\$',
        'amount': 4218.55,
        'flag': '🇺🇸',
        'rate': 1.00,
      },
      {
        'currency': 'EUR',
        'symbol': '€',
        'amount': 1840.20,
        'flag': '🇪🇺',
        'rate': 0.9248,
      },
      {
        'currency': 'GBP',
        'symbol': '£',
        'amount': 612.40,
        'flag': '🇬🇧',
        'rate': 0.7820,
      },
      {
        'currency': 'JPY',
        'symbol': '¥',
        'amount': 142800.00,
        'flag': '🇯🇵',
        'rate': 156.42,
      },
      {
        'currency': 'INR',
        'symbol': '₹',
        'amount': 28450.00,
        'flag': '🇮🇳',
        'rate': 83.20,
      },
      {
        'currency': 'AED',
        'symbol': 'د.إ',
        'amount': 980.00,
        'flag': '🇦🇪',
        'rate': 3.6725,
      },
    ],
    'transactions': [
      {
        'id': 'tx-1001',
        'type': 'payment',
        'description': 'Sushi Saito — dinner',
        'merchant': 'Sushi Saito',
        'amount': 184.00,
        'currency': 'USD',
        'date': '2026-06-13T21:14:00Z',
        'category': 'Dining',
        'location': 'Tokyo, JP',
        'country': 'Japan',
        'countryFlag': '🇯🇵',
        'icon': 'restaurant',
      },
      {
        'id': 'tx-1002',
        'type': 'payment',
        'description': 'Aman Tokyo — 2 nights',
        'merchant': 'Aman Tokyo',
        'amount': 1860.00,
        'currency': 'USD',
        'date': '2026-06-13T11:01:00Z',
        'category': 'Lodging',
        'location': 'Tokyo, JP',
        'country': 'Japan',
        'countryFlag': '🇯🇵',
        'icon': 'hotel',
      },
      {
        'id': 'tx-1003',
        'type': 'convert',
        'description': 'USD → JPY',
        'amount': 500.00,
        'currency': 'USD',
        'date': '2026-06-12T08:55:00Z',
        'category': 'FX',
        'icon': 'sync_alt',
      },
      {
        'id': 'tx-1004',
        'type': 'payment',
        'description': 'United Airlines — UA837',
        'merchant': 'United',
        'amount': 1240.00,
        'currency': 'USD',
        'date': '2026-05-22T14:21:00Z',
        'category': 'Travel',
        'location': 'San Francisco, US',
        'country': 'United States',
        'countryFlag': '🇺🇸',
        'icon': 'flight',
      },
      {
        'id': 'tx-1005',
        'type': 'payment',
        'description': 'JR East · Shinkansen pass',
        'merchant': 'JR East',
        'amount': 220.00,
        'currency': 'USD',
        'date': '2026-06-13T09:30:00Z',
        'category': 'Transport',
        'location': 'Tokyo, JP',
        'country': 'Japan',
        'countryFlag': '🇯🇵',
        'icon': 'train',
      },
      {
        'id': 'tx-1006',
        'type': 'receive',
        'description': 'Refund · Hotel Hilton',
        'merchant': 'Hilton',
        'amount': 162.00,
        'currency': 'USD',
        'date': '2026-05-30T17:40:00Z',
        'category': 'Lodging',
        'icon': 'undo',
      },
      {
        'id': 'tx-1007',
        'type': 'payment',
        'description': 'TeamLab Borderless · 2 tickets',
        'merchant': 'TeamLab',
        'amount': 78.00,
        'currency': 'USD',
        'date': '2026-06-14T13:00:00Z',
        'category': 'Activities',
        'location': 'Tokyo, JP',
        'country': 'Japan',
        'countryFlag': '🇯🇵',
        'icon': 'museum',
      },
      {
        'id': 'tx-1008',
        'type': 'payment',
        'description': 'Uber · Narita → Hotel',
        'merchant': 'Uber',
        'amount': 92.40,
        'currency': 'USD',
        'date': '2026-06-12T22:50:00Z',
        'category': 'Transport',
        'location': 'Tokyo, JP',
        'country': 'Japan',
        'countryFlag': '🇯🇵',
        'icon': 'local_taxi',
      },
      {
        'id': 'tx-1009',
        'type': 'payment',
        'description': 'Apple Card · monthly',
        'merchant': 'Apple',
        'amount': 64.00,
        'currency': 'USD',
        'date': '2026-06-01T00:00:00Z',
        'category': 'Subscription',
        'icon': 'apple',
      },
      {
        'id': 'tx-1010',
        'type': 'payment',
        'description': 'Allianz · travel insurance',
        'merchant': 'Allianz',
        'amount': 48.50,
        'currency': 'USD',
        'date': '2026-05-28T11:00:00Z',
        'category': 'Insurance',
        'icon': 'shield',
      },
      {
        'id': 'tx-1011',
        'type': 'payment',
        'description': 'Le Comptoir du Relais',
        'merchant': 'Le Comptoir',
        'amount': 92.10,
        'currency': 'EUR',
        'date': '2026-06-22T20:14:00Z',
        'category': 'Dining',
        'location': 'Paris, FR',
        'country': 'France',
        'countryFlag': '🇫🇷',
        'icon': 'restaurant',
      },
      {
        'id': 'tx-1012',
        'type': 'payment',
        'description': 'Ritz Paris · 3 nights',
        'merchant': 'Ritz Paris',
        'amount': 2840.00,
        'currency': 'EUR',
        'date': '2026-06-23T11:00:00Z',
        'category': 'Lodging',
        'location': 'Paris, FR',
        'country': 'France',
        'countryFlag': '🇫🇷',
        'icon': 'hotel',
      },
    ],
    'state': {
      'defaultCurrency': 'USD',
      'activeCountry': 'United States',
    },
  };

  static const Map<String, dynamic> _loyalty = {
    'tier': 'Citizen',
    'points': 18420,
    'pointsToNext': 1580,
    'stamps': [
      {'flag': '🇯🇵', 'title': 'Japan', 'date': '2026-06-12'},
      {'flag': '🇫🇷', 'title': 'France', 'date': '2026-06-19'},
      {'flag': '🇺🇸', 'title': 'USA', 'date': '2026-06-30'},
      {'flag': '🇦🇪', 'title': 'UAE', 'date': '2025-11-04'},
      {'flag': '🇬🇧', 'title': 'UK', 'date': '2025-09-22'},
      {'flag': '🇮🇳', 'title': 'India', 'date': '2025-08-04'},
      {'flag': '🇮🇩', 'title': 'Indonesia', 'date': '2024-12-22'},
      {'flag': '🇸🇬', 'title': 'Singapore', 'date': '2024-09-15'},
      {'flag': '🇨🇭', 'title': 'Switzerland', 'date': '2024-04-09'},
    ],
  };

  static const List<Map<String, dynamic>> _safetyContacts = [
    {
      'id': 'sc-1',
      'name': 'Aanya Kapoor',
      'relation': 'Spouse',
      'phone': '+1 415 555 0119',
      'email': 'aanya@example.com',
      'priority': 1,
    },
    {
      'id': 'sc-2',
      'name': 'Vikram Kumar',
      'relation': 'Father',
      'phone': '+91 98330 41122',
      'email': 'vikram@example.com',
      'priority': 2,
    },
    {
      'id': 'sc-3',
      'name': 'Priya Mehta',
      'relation': 'Friend',
      'phone': '+44 7700 900410',
      'email': 'priya@example.com',
      'priority': 3,
    },
  ];

  static const Map<String, dynamic> _score = {
    'score': 826,
    'tier': 2,
    'history': [712, 728, 740, 765, 778, 790, 802, 808, 812, 818, 822, 826],
    'factors': [
      {
        'id': 'verified',
        'label': 'Identity verified',
        'weight': 0.30,
        'value': 1.0,
      },
      {
        'id': 'travel',
        'label': 'Travel consistency',
        'weight': 0.25,
        'value': 0.92,
      },
      {
        'id': 'wallet',
        'label': 'Wallet hygiene',
        'weight': 0.20,
        'value': 0.88,
      },
      {
        'id': 'safety',
        'label': 'Safety profile',
        'weight': 0.15,
        'value': 1.0,
      },
      {
        'id': 'social',
        'label': 'Social proof',
        'weight': 0.10,
        'value': 0.74,
      },
    ],
  };

  static const Map<String, dynamic> _budget = {
    'caps': [
      {'scope': 'Travel', 'cap': 6000, 'used': 4180.20, 'currency': 'USD'},
      {'scope': 'Dining', 'cap': 1500, 'used': 980.50, 'currency': 'USD'},
      {'scope': 'Lodging', 'cap': 4000, 'used': 2640.00, 'currency': 'USD'},
      {'scope': 'Transport', 'cap': 800, 'used': 412.75, 'currency': 'USD'},
      {'scope': 'Other', 'cap': 600, 'used': 144.30, 'currency': 'USD'},
    ],
  };

  static const Map<String, dynamic> _fraud = {
    'items': [
      {
        'id': 'fr-1',
        'severity': 'low',
        'title': 'Card-not-present in Tokyo',
        'subtitle': 'Same merchant, same amount, 2 nights apart',
      },
      {
        'id': 'fr-2',
        'severity': 'info',
        'title': 'New device on wallet',
        'subtitle': 'Pixel 8 Pro · added 12 Jun',
      },
    ],
  };

  static const Map<String, dynamic> _exchangeRates = {
    'base': 'USD',
    'asOf': '2026-06-12T08:00:00Z',
    'rates': {
      'USD': 1.00,
      'EUR': 0.9248,
      'GBP': 0.7820,
      'JPY': 156.42,
      'INR': 83.20,
      'AED': 3.6725,
      'SGD': 1.3450,
      'AUD': 1.5160,
      'CAD': 1.3700,
      'CHF': 0.9020,
    },
  };

  static const Map<String, dynamic> _visaPolicies = {
    'policies': [
      {
        'destination': 'Japan',
        'flag': '🇯🇵',
        'status': 'evisa',
        'maxStay': 90
      },
      {
        'destination': 'France',
        'flag': '🇫🇷',
        'status': 'visa-required',
        'maxStay': 90,
      },
      {
        'destination': 'United States',
        'flag': '🇺🇸',
        'status': 'visa-required',
        'maxStay': 180,
      },
      {
        'destination': 'United Arab Emirates',
        'flag': '🇦🇪',
        'status': 'visa-on-arrival',
        'maxStay': 60,
      },
      {
        'destination': 'Singapore',
        'flag': '🇸🇬',
        'status': 'visa-free',
        'maxStay': 30,
      },
      {
        'destination': 'Indonesia',
        'flag': '🇮🇩',
        'status': 'visa-on-arrival',
        'maxStay': 30,
      },
      {
        'destination': 'United Kingdom',
        'flag': '🇬🇧',
        'status': 'visa-required',
        'maxStay': 180,
      },
    ],
  };

  static const Map<String, dynamic> _visaPolicy = {
    'destination': 'Japan',
    'citizenship': 'India',
    'status': 'evisa',
    'maxStay': 90,
    'fee': 25,
    'currency': 'USD',
  };

  static const Map<String, dynamic> _insurancePlans = {
    'plans': [
      {
        'id': 'ins-essential',
        'name': 'Essential',
        'price': 28,
        'currency': 'USD',
        'coverage': '\$50k medical',
      },
      {
        'id': 'ins-premium',
        'name': 'Premium',
        'price': 48,
        'currency': 'USD',
        'coverage': '\$250k medical · trip cancellation',
      },
      {
        'id': 'ins-elite',
        'name': 'Elite',
        'price': 92,
        'currency': 'USD',
        'coverage': 'Unlimited · concierge · adventure',
      },
    ],
  };

  static const Map<String, dynamic> _esimPlans = {
    'plans': [
      {
        'id': 'esim-jp-5gb',
        'country': 'Japan',
        'flag': '🇯🇵',
        'data': '5 GB',
        'days': 15,
        'price': 18,
        'currency': 'USD',
      },
      {
        'id': 'esim-fr-10gb',
        'country': 'France',
        'flag': '🇫🇷',
        'data': '10 GB',
        'days': 30,
        'price': 24,
        'currency': 'USD',
      },
      {
        'id': 'esim-eu-20gb',
        'country': 'EU 36',
        'flag': '🇪🇺',
        'data': '20 GB',
        'days': 30,
        'price': 38,
        'currency': 'USD',
      },
      {
        'id': 'esim-global',
        'country': 'Global 130',
        'flag': '🌍',
        'data': '6 GB',
        'days': 21,
        'price': 42,
        'currency': 'USD',
      },
    ],
  };

  static const Map<String, dynamic> _hotels = {
    'items': [
      {
        'title': 'Aman Tokyo',
        'subtitle': 'Otemachi · suite · breakfast incl.',
        'price': 920,
        'currency': 'USD',
        'rating': 4.9,
      },
      {
        'title': 'Park Hyatt Tokyo',
        'subtitle': 'Shinjuku · skyline view',
        'price': 540,
        'currency': 'USD',
        'rating': 4.8,
      },
      {
        'title': 'Hoshinoya Tokyo',
        'subtitle': 'Otemachi · ryokan · onsen',
        'price': 680,
        'currency': 'USD',
        'rating': 4.8,
      },
      {
        'title': 'Andaz Tokyo',
        'subtitle': 'Toranomon · rooftop bar',
        'price': 460,
        'currency': 'USD',
        'rating': 4.7,
      },
      {
        'title': 'Conrad Tokyo',
        'subtitle': 'Bay view · spa · executive',
        'price': 410,
        'currency': 'USD',
        'rating': 4.6,
      },
    ],
  };

  static const Map<String, dynamic> _food = {
    'items': [
      {
        'title': 'Sushi Saito',
        'subtitle': '★ 4.9 · 3 Michelin · Akasaka',
        'price': 380,
        'currency': 'USD',
        'rating': 4.9,
      },
      {
        'title': 'Den',
        'subtitle': '★ 4.8 · Modern kaiseki · Jimbocho',
        'price': 220,
        'currency': 'USD',
        'rating': 4.8,
      },
      {
        'title': 'Tonkatsu Maisen',
        'subtitle': '★ 4.6 · Aoyama original',
        'price': 28,
        'currency': 'USD',
        'rating': 4.6,
      },
      {
        'title': 'Ichiran Ramen',
        'subtitle': '★ 4.5 · Shibuya · 24/7',
        'price': 14,
        'currency': 'USD',
        'rating': 4.5,
      },
      {
        'title': 'Le Comptoir du Relais',
        'subtitle': '★ 4.7 · Paris 6e · classic bistro',
        'price': 90,
        'currency': 'EUR',
        'rating': 4.7,
      },
    ],
  };

  static const Map<String, dynamic> _rides = {
    'items': [
      {
        'title': 'Uber Black',
        'subtitle': '6 min · Mercedes E-class',
        'price': 38,
        'currency': 'USD',
        'rating': 4.9,
      },
      {
        'title': 'Uber XL',
        'subtitle': '4 min · 6 seats',
        'price': 24,
        'currency': 'USD',
        'rating': 4.8,
      },
      {
        'title': 'Uber Comfort',
        'subtitle': '3 min · newer cars',
        'price': 18,
        'currency': 'USD',
        'rating': 4.7,
      },
      {
        'title': 'Lyft Standard',
        'subtitle': '5 min · ride share',
        'price': 14,
        'currency': 'USD',
        'rating': 4.7,
      },
      {
        'title': 'Bolt',
        'subtitle': '7 min · economical',
        'price': 11,
        'currency': 'USD',
        'rating': 4.6,
      },
    ],
  };

  static const Map<String, dynamic> _localServices = {
    'items': [
      {
        'title': 'Airport pickup · Narita → Hotel',
        'subtitle': 'Pre-booked · English-speaking driver',
        'price': 92,
        'currency': 'USD',
        'rating': 4.9,
      },
      {
        'title': 'Private guide · Asakusa half-day',
        'subtitle': '4 h · groups up to 6',
        'price': 180,
        'currency': 'USD',
        'rating': 4.9,
      },
      {
        'title': 'Tea ceremony · Ginza',
        'subtitle': '1.5 h · traditional setting',
        'price': 64,
        'currency': 'USD',
        'rating': 4.8,
      },
      {
        'title': 'Sushi-making class',
        'subtitle': '2 h · Tsukiji area',
        'price': 88,
        'currency': 'USD',
        'rating': 4.8,
      },
      {
        'title': 'Bullet-train transfer',
        'subtitle': 'JR pass exchange · pickup at hotel',
        'price': 42,
        'currency': 'USD',
        'rating': 4.7,
      },
    ],
  };

  static const Map<String, dynamic> _weather = {
    'iata': 'NRT',
    'days': [
      {'date': '2026-06-12', 'high': 28, 'low': 22, 'kind': 'partly-cloudy'},
      {'date': '2026-06-13', 'high': 27, 'low': 21, 'kind': 'cloudy'},
      {'date': '2026-06-14', 'high': 25, 'low': 20, 'kind': 'rain'},
      {'date': '2026-06-15', 'high': 26, 'low': 21, 'kind': 'rain'},
      {'date': '2026-06-16', 'high': 28, 'low': 22, 'kind': 'partly-cloudy'},
      {'date': '2026-06-17', 'high': 30, 'low': 24, 'kind': 'sunny'},
      {'date': '2026-06-18', 'high': 31, 'low': 25, 'kind': 'sunny'},
    ],
  };
}
