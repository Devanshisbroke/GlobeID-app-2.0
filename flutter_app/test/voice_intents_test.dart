import 'package:flutter_test/flutter_test.dart';
import 'package:globeid/domain/voice_intents.dart';

void main() {
  group('voice intents', () {
    test('strips wake word and navigates to wallet', () {
      final intent = parseVoiceIntent('Hey Globe, open wallet');

      expect(intent, isA<NavigateIntent>());
      expect((intent as NavigateIntent).path, '/wallet');
    });

    test('resolves numbered trips and passes', () {
      final trip = parseVoiceIntent('trip number 3');
      final pass = parseVoiceIntent('pass 2');

      expect(trip, isA<NumericIntent>());
      expect((trip as NumericIntent).target, 'trip');
      expect(trip.index, 3);
      expect(pass, isA<NumericIntent>());
      expect((pass as NumericIntent).target, 'pass');
      expect(pass.index, 2);
    });

    test('parses compose intent with place and date', () {
      final intent = parseVoiceIntent('book a hotel in tokyo for next friday');

      expect(intent, isA<ComposeIntent>());
      final compose = intent as ComposeIntent;
      expect(compose.verb, 'book');
      expect(compose.subject, 'hotel');
      expect(compose.meta['place'], 'tokyo');
      expect(compose.meta['when'], 'next friday');
    });

    test('parses translate and reminder commands', () {
      final translate = parseVoiceIntent('translate this into French');
      final reminder = parseVoiceIntent('remind me to pack at 7pm');

      expect(translate, isA<TranslateIntent>());
      expect((translate as TranslateIntent).toLang, 'fr');
      expect(reminder, isA<RemindIntent>());
      expect((reminder as RemindIntent).text, 'pack');
      expect(reminder.whenLocal, '7pm');
    });

    test('suggests likely commands for unknown transcript', () {
      final suggestions = suggestVoiceIntents('passport');

      expect(suggestions, contains('scan a passport'));
      expect(suggestions, contains('open passport book'));
    });
  });
}
