// Barrel for the GlobeID UI/UX-bible widget primitives.
//
// Import via:
//   import 'package:globeid/widgets/bible/bible.dart';
//
// All widgets here are bible-aligned (substrate / tone / signal,
// named curves, named transitions, materials, lighting). New
// flagship surfaces should source from here, not from the lower-
// level `widgets/premium/*`.

// Re-export the bible tokens (substrate / tone / signal palettes,
// curves, materials, lighting) so any feature screen can import the
// barrel and have access to the entire bible language.
export '../../app/theme/ux_bible.dart';
export 'bible_hero_card.dart';
export 'bible_top_bar.dart';
export 'ligature_text.dart';
export 'living_gradient.dart';
export 'solari_flap.dart';
