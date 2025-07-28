import 'package:test/test.dart';
import 'package:weak_collections/weak_collections.dart';

import '../tools.dart';

void main() {
  group('WeakHashMap', () {
    test('.contains()', () {
      final map = WeakHashMap<TestVal, String>();

      final v1 = TestVal('a');
      final v2 = TestVal('b');
      final v3 = TestVal('c');
      final nonExisting = TestVal('d');

      map[v1] = v1.debugName;
      map[v2] = v2.debugName;
      map[v3] = v3.debugName;

      expect(map.length, equals(3));
      expect(map.containsKey(v1), isTrue);
      expect(map.containsKey(v2), isTrue);
      expect(map.containsKey(v3), isTrue);
      expect(map.containsValue(v3.debugName), isTrue);
      expect(map.containsKey(nonExisting), isFalse);
    });

    test('.remove()', () {
      final map = WeakHashMap<TestVal, String>();

      final v1 = TestVal('a');
      final v2 = TestVal('b');
      final v3 = TestVal('c');

      map[v1] = v1.debugName;
      map[v2] = v2.debugName;
      map[v3] = v3.debugName;

      map.remove(v2);

      expect(map.length, equals(2));
      expect(map.containsKey(v2), isFalse);
      expect(map.containsValue(v2.debugName), isFalse);
    });

    test('.put()', () {
      final map = WeakHashMap<TestVal, String>();

      final v1 = TestVal('a');
      final v2 = TestVal('b');
      final v3 = TestVal('c');

      map[v1] = v1.debugName;
      map[v2] = v2.debugName;
      map[v3] = v3.debugName;
      map[v3] = '${v3.debugName} next';

      expect(map.length, equals(3));
      expect(map.containsKey(v3), true);
      expect(map.containsValue(v3.debugName), false);
    });
  });
}
