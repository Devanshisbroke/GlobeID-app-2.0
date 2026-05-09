/// Dart port of `src/lib/voiceIntents.ts`. Deterministic regex grammar
/// for voice commands. Same input → same output. Designed to run on-
/// device in <50 ms.
sealed class VoiceIntent {
  const VoiceIntent(this.label);
  final String label;
}

class NavigateIntent extends VoiceIntent {
  const NavigateIntent(this.path, super.label);
  final String path;
}

class ActionIntent extends VoiceIntent {
  const ActionIntent(this.action, super.label);
  final String action; // refresh | start-scan | toggle-language
}

class QueryIntent extends VoiceIntent {
  const QueryIntent(this.query, super.label);
  final String query; // wallet-balance | next-trip | score | weather
}

class SearchIntent extends VoiceIntent {
  const SearchIntent(this.target, super.label);
  final String target; // hotels | rides | food | visa
}

class NumericIntent extends VoiceIntent {
  const NumericIntent(this.target, this.index, super.label);
  final String target; // trip | pass | document
  final int index;
}

class TranslateIntent extends VoiceIntent {
  const TranslateIntent(this.toLang, super.label);
  final String toLang;
}

class RemindIntent extends VoiceIntent {
  const RemindIntent(this.text, this.whenLocal, super.label);
  final String text;
  final String? whenLocal;
}

class ComposeIntent extends VoiceIntent {
  const ComposeIntent(this.verb, this.subject, this.meta, super.label);
  final String verb; // book | find | plan
  final String subject;
  final Map<String, String> meta;
}

class UnknownIntent extends VoiceIntent {
  const UnknownIntent(this.transcript) : super('Unknown');
  final String transcript;
}

const _wakeWords = [
  'hey globe',
  'hey globeid',
  'ok globe',
  'okay guide',
];

const _langMap = {
  'english': 'en',
  'spanish': 'es',
  'french': 'fr',
  'german': 'de',
  'italian': 'it',
  'portuguese': 'pt',
  'japanese': 'ja',
  'chinese': 'zh',
  'korean': 'ko',
  'hindi': 'hi',
  'arabic': 'ar',
};

String _stripWake(String input) {
  var t = input.trim().toLowerCase();
  for (final w in _wakeWords) {
    if (t.startsWith(w)) {
      t = t.substring(w.length).trim();
      if (t.startsWith(',')) t = t.substring(1).trim();
      break;
    }
  }
  return t;
}

VoiceIntent parseVoiceIntent(String transcript) {
  if (transcript.trim().isEmpty) return UnknownIntent(transcript);
  final t = _stripWake(transcript);

  // Navigation
  final navRules = <RegExp, _NavRule>{
    RegExp(r'\b(open |go to |show )?(home|dashboard)\b'):
        const _NavRule('/', 'Open Home'),
    RegExp(r'\b(open |go to |show )?(wallet|cards)\b'):
        const _NavRule('/wallet', 'Open Wallet'),
    RegExp(r'\b(open |go to |show )?(identity|passport)\b'):
        const _NavRule('/identity', 'Open Identity'),
    RegExp(r'\b(open |go to |show )?(travel|trips)\b'):
        const _NavRule('/travel', 'Open Travel'),
    RegExp(r'\b(open |go to |show )?(map|globe)\b'):
        const _NavRule('/map', 'Open Map'),
    RegExp(r'\b(open |go to |show )?(services|hub)\b'):
        const _NavRule('/services', 'Open Services'),
    RegExp(r'\b(scan|scanner)\b'): const _NavRule('/scan', 'Open Scanner'),
    RegExp(r'\b(profile|settings)\b'):
        const _NavRule('/profile', 'Open Profile'),
    RegExp(r'\b(vault|documents)\b'): const _NavRule('/vault', 'Open Vault'),
    RegExp(r'\b(analytics|insights)\b'):
        const _NavRule('/analytics', 'Open Analytics'),
  };
  for (final entry in navRules.entries) {
    if (entry.key.hasMatch(t)) {
      return NavigateIntent(entry.value.path, entry.value.label);
    }
  }

  // Numeric: "trip 3", "pass 2"
  final num = RegExp(r'\b(trip|pass|document)\s+(\d+)\b').firstMatch(t);
  if (num != null) {
    return NumericIntent(num.group(1)!, int.parse(num.group(2)!),
        'Open ${num.group(1)} ${num.group(2)}');
  }

  // Translate
  final tr = RegExp(r'\btranslate(?: this)?(?: to)?\s+(\w+)\b').firstMatch(t);
  if (tr != null) {
    final lang = _langMap[tr.group(1)] ?? tr.group(1)!;
    return TranslateIntent(lang, 'Translate to $lang');
  }

  // Remind: "remind me to pack at 7pm"
  final rem = RegExp(r'^remind me to (.+?)(?: at (.+))?$').firstMatch(t);
  if (rem != null) {
    return RemindIntent(rem.group(1)!.trim(), rem.group(2)?.trim(), 'Reminder');
  }

  // Compose: "book a hotel in tokyo for next friday"
  final cmp = RegExp(
          r'^(book|find|plan)\s+(?:a\s+|the\s+)?(\w+)(?:\s+in\s+(\w+))?(?:\s+for\s+(.+))?$')
      .firstMatch(t);
  if (cmp != null) {
    final meta = <String, String>{};
    if (cmp.group(3) != null) meta['where'] = cmp.group(3)!;
    if (cmp.group(4) != null) meta['when'] = cmp.group(4)!;
    return ComposeIntent(
      cmp.group(1)!,
      cmp.group(2)!,
      meta,
      '${cmp.group(1)} ${cmp.group(2)}',
    );
  }

  // Search
  if (RegExp(r'\b(hotels?|rooms?|stays?)\b').hasMatch(t)) {
    return const SearchIntent('hotels', 'Search hotels');
  }
  if (RegExp(r'\b(rides?|taxis?|ubers?|cabs?)\b').hasMatch(t)) {
    return const SearchIntent('rides', 'Search rides');
  }
  if (RegExp(r'\b(food|restaurants?|dinner|lunch)\b').hasMatch(t)) {
    return const SearchIntent('food', 'Search food');
  }
  if (RegExp(r'\b(visa|visas)\b').hasMatch(t)) {
    return const SearchIntent('visa', 'Visa lookup');
  }

  // Query
  if (RegExp(r'\b(balance|how much)\b').hasMatch(t)) {
    return const QueryIntent('wallet-balance', 'Wallet balance');
  }
  if (RegExp(r'\b(next trip|upcoming flight)\b').hasMatch(t)) {
    return const QueryIntent('next-trip', 'Next trip');
  }
  if (RegExp(r'\b(score|tier)\b').hasMatch(t)) {
    return const QueryIntent('score', 'Identity score');
  }
  if (RegExp(r'\b(weather|forecast)\b').hasMatch(t)) {
    return const QueryIntent('weather', 'Weather');
  }

  // Action
  if (RegExp(r'\b(refresh|reload|sync)\b').hasMatch(t)) {
    return const ActionIntent('refresh', 'Refresh');
  }
  if (RegExp(r'\b(start scan|scan now)\b').hasMatch(t)) {
    return const ActionIntent('start-scan', 'Start scan');
  }
  if (RegExp(r'\b(toggle language|change language)\b').hasMatch(t)) {
    return const ActionIntent('toggle-language', 'Toggle language');
  }

  return UnknownIntent(transcript);
}

/// Suggest likely voice commands for an unrecognized transcript.
///
/// Performs simple keyword overlap scoring against a catalog of known
/// commands. Returns the top [max] matches, each as a human-readable
/// phrase the user can tap to execute.
List<String> suggestVoiceIntents(String transcript, {int max = 5}) {
  final words = transcript.toLowerCase().split(RegExp(r'\s+'));
  final scored = <(double, String)>[];
  for (final entry in _commandCatalog) {
    final keywords = entry.$1;
    var score = 0.0;
    for (final w in words) {
      for (final kw in keywords) {
        if (kw.contains(w) || w.contains(kw)) {
          score += 1.0;
        }
      }
    }
    if (score > 0) scored.add((score, entry.$2));
  }
  scored.sort((a, b) => b.$1.compareTo(a.$1));
  return scored.take(max).map((e) => e.$2).toList();
}

const _commandCatalog = <(List<String>, String)>[
  (['open', 'home', 'dashboard'], 'open home'),
  (['open', 'wallet', 'cards', 'balance'], 'open wallet'),
  (['open', 'identity', 'passport', 'id'], 'open identity'),
  (['open', 'travel', 'trips', 'flight'], 'open travel'),
  (['open', 'map', 'globe', 'earth'], 'open map'),
  (['open', 'services', 'hub'], 'open services'),
  (['scan', 'scanner', 'qr', 'barcode'], 'open scanner'),
  (['scan', 'passport', 'mrz', 'document'], 'scan a passport'),
  (['passport', 'book', 'stamps'], 'open passport book'),
  (['vault', 'documents', 'secure'], 'open vault'),
  (['profile', 'settings', 'account'], 'open profile'),
  (['analytics', 'insights', 'stats'], 'open analytics'),
  (['book', 'hotel', 'stay', 'room'], 'book a hotel'),
  (['book', 'flight', 'plane', 'airline'], 'find flights'),
  (['find', 'ride', 'taxi', 'car'], 'find a ride'),
  (['food', 'restaurant', 'dinner', 'eat'], 'find food'),
  (['translate', 'language', 'speak'], 'translate to a language'),
  (['remind', 'reminder', 'alarm', 'pack'], 'remind me to pack'),
  (['weather', 'forecast', 'temperature'], 'check weather'),
  (['balance', 'money', 'currency', 'exchange'], 'check wallet balance'),
  (['trip', 'plan', 'planner', 'itinerary'], 'plan a trip'),
  (['visa', 'entry', 'requirements'], 'check visa requirements'),
  (['copilot', 'ai', 'assistant', 'help'], 'open copilot'),
  (['refresh', 'reload', 'sync', 'update'], 'refresh data'),
];

class _NavRule {
  const _NavRule(this.path, this.label);
  final String path;
  final String label;
}
