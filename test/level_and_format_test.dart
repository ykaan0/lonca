import 'package:flutter_test/flutter_test.dart';
import 'package:lonca/utils/format.dart';
import 'package:lonca/utils/level.dart';

void main() {
  group('LevelInfo', () {
    test('starts at level 1 with 0 progress', () {
      final info = LevelInfo.user(0);
      expect(info.level, 1);
      expect(info.progress, 0.0);
    });

    test('advances user level at 2 hours', () {
      final info = LevelInfo.user(2 * 3600);
      expect(info.level, 2);
      expect(info.progress, 0.0);
    });

    test('advances group level at 5 hours', () {
      final info = LevelInfo.group(5 * 3600);
      expect(info.level, 2);
    });
  });

  group('Format helpers', () {
    test('clock formats hh:mm:ss', () {
      expect(clock(3661), '01:01:01');
      expect(clock(0), '00:00:00');
    });

    test('initials handles Turkish uppercase', () {
      expect(initials('irem ışık'), 'İI');
      expect(initials('Ahmet'), 'A');
    });
  });
}

