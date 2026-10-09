import 'package:flutter_test/flutter_test.dart';
import 'package:paperflick/engine/paperflick_engine.dart';
import 'package:paperflick/services/settings_service.dart';

void main() {
  test('LevelSpec is deterministic for the same inputs', () {
    for (final diff in FlickDifficulty.values) {
      for (final mode in FlickMode.values) {
        final a = PaperFlickEngine.specFor(7, diff, mode);
        final b = PaperFlickEngine.specFor(7, diff, mode);
        expect(a.binX, b.binX);
        expect(a.binY, b.binY);
        expect(a.wind, b.wind);
        expect(a.moving, b.moving);
        expect(a.binHalf, b.binHalf);
        expect(a.gravity, b.gravity);
      }
    }
  });

  test('LevelSpec varies across levels (real progression)', () {
    final l1 = PaperFlickEngine.specFor(1, FlickDifficulty.casual, FlickMode.levelRun);
    final l20 = PaperFlickEngine.specFor(20, FlickDifficulty.casual, FlickMode.levelRun);
    // Level 1 casual has no wind; level 20 has wind and a moving bin.
    expect(l1.wind, 0);
    expect(l20.wind.abs() > 1 || l20.moving, isTrue);
    // Harder difficulties start wind earlier.
    final t1 = PaperFlickEngine.specFor(1, FlickDifficulty.trickshot, FlickMode.levelRun);
    expect(t1.wind.abs() > 1, isTrue);
  });

  test('LevelSpec respects physical bounds', () {
    for (int level = 1; level <= 40; level++) {
      for (final diff in FlickDifficulty.values) {
        final s = PaperFlickEngine.specFor(level, diff, FlickMode.levelRun);
        expect(s.binX, inInclusiveRange(0.12, 0.88));
        expect(s.binY, inInclusiveRange(0.10, 0.40));
        expect(s.binHalf, inInclusiveRange(0.030, 0.070));
        expect(s.gravity, greaterThan(0));
      }
    }
  });

  test('Player names encode as one JSON string, decode safely', () {
    // ONE order-preserving JSON string — never setStringList (Android's
    // StringSet backing scrambles slot order on restart).
    expect(FlickSettings.encodePlayerNames(['Desk Champ']), '["Desk Champ"]');
    expect(FlickSettings.decodePlayerNames('["Desk Champ"]'), ['Desk Champ']);
    expect(FlickSettings.decodePlayerNames(null), ['Player One']);
    expect(FlickSettings.decodePlayerNames('not json'), ['Player One']);
    expect(FlickSettings.decodePlayerNames('""'), ['Player One']);
    expect(FlickSettings.decodePlayerNames('[]'), ['Player One']);
    // Tolerates the very first schema (a bare JSON string).
    expect(FlickSettings.decodePlayerNames('"Desk Champ"'), ['Desk Champ']);
  });
}
