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

    test('.contains() with Rewrite equals', () {
      final map = WeakHashMap<TestEqualsObject, String>();

      final a = TestEqualsObject('a');
      final b = TestEqualsObject('b');
      final c = TestEqualsObject('c');
      final c2 = TestEqualsObject('c');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';

      expect(map.length, equals(3));
      expect(map.containsKey(a), isTrue);
      expect(map.containsKey(b), isTrue);
      expect(map.containsKey(c), isTrue);
      expect(map.containsKey(c2), isTrue);
    });

    test('.get()', () {
      final map = WeakHashMap<TestVal, String>();

      final a = TestVal('a');
      final b = TestVal('b');
      final c = TestVal('c');
      final nonExisting = TestVal('d');

      map[a] = a.debugName;
      map[b] = b.debugName;
      map[c] = c.debugName;

      expect(map.length, equals(3));
      expect(map.containsKey(a), isTrue);
      expect(map.containsKey(b), isTrue);
      expect(map.containsKey(c), isTrue);
      expect(map.containsValue(c.debugName), isTrue);
      expect(map.containsKey(nonExisting), isFalse);

      expect(map[a], 'a');
      expect(map[b], 'b');
      expect(map[c], 'c');
      expect(map[nonExisting], isNull);
    });

    test('.get() with Rewrite equals', () {
      final map = WeakHashMap<TestEqualsObject, String>();

      final a = TestEqualsObject('a');
      final b = TestEqualsObject('b');
      final c = TestEqualsObject('c');
      final c2 = TestEqualsObject('c');
      final nonExisting = TestEqualsObject('d');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';

      expect(map.length, equals(3));
      expect(map.containsKey(a), isTrue);
      expect(map.containsKey(b), isTrue);
      expect(map.containsKey(c), isTrue);
      expect(map.containsValue('c'), isTrue);
      expect(map.containsKey(nonExisting), isFalse);

      expect(map[a], 'a');
      expect(map[b], 'b');
      expect(map[c], 'c');
      expect(map[c2], 'c');
      expect(map[nonExisting], isNull);
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

    test('.remove() with Rewrite equals', () {
      final map = WeakHashMap<TestEqualsObject, String>();

      final a = TestEqualsObject('a');
      final b = TestEqualsObject('b');
      final c = TestEqualsObject('c');
      final c2 = TestEqualsObject('c');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';

      map.remove(c2);

      expect(map.length, equals(2));
      expect(map.containsKey(b), isTrue);
      expect(map.containsKey(c), isFalse);
      expect(map.containsValue('c'), isFalse);
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

    test('.put() with Rewrite equals', () {
      final map = WeakHashMap<TestEqualsObject, String>();

      final a = TestEqualsObject('a');
      final b = TestEqualsObject('b');
      final c = TestEqualsObject('c');
      final c2 = TestEqualsObject('c');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';

      map[c2] = 'd';

      expect(map.length, equals(3));
      expect(map.containsKey(b), isTrue);

      expect(map.containsKey(c), isTrue);
      expect(map.containsValue('c'), isFalse);
      expect(map.containsValue('d'), isTrue);
    });
  });

  group('WeakHashMap basic operations', () {
    test('insert and retrieve values', () {
      final map = WeakHashMap<TestVal, int>();
      final a = TestVal('a');
      final b = TestVal('b');

      map[a] = 1;
      map[b] = 2;

      expect(map[a], 1);
      expect(map[b], 2);
      expect(map.containsKey(a), isTrue);
      expect(map.containsValue(2), isTrue);
      expect(map.length, 2);
    });

    test('update existing value', () {
      final map = WeakHashMap<TestVal, int>();
      final a = TestVal('a');
      map[a] = 10;

      final newValue = map.update(a, (v) => v + 5);
      expect(newValue, 15);
      expect(map[a], 15);
    });

    test('putIfAbsent should not overwrite', () {
      final map = WeakHashMap<TestVal, int>();
      final a = TestVal('a');
      map[a] = 1;

      final result = map.putIfAbsent(a, () => 99);
      expect(result, 1);
      expect(map[a], 1);
    });

    test('remove key', () {
      final map = WeakHashMap<TestVal, int>();
      final a = TestVal('a');
      map[a] = 123;

      final removed = map.remove(a);
      expect(removed, 123);
      expect(map.containsKey(a), isFalse);
    });

    test('removeWhere', () {
      final map = WeakHashMap<TestVal, int>();
      final a = TestVal('a');
      final b = TestVal('b');
      final c = TestVal('c');
      map[a] = 1;
      map[b] = 2;
      map[c] = 3;

      map.removeWhere((k, v) => v.isOdd);
      expect(map.length, 1);
      expect(map.containsValue(2), isTrue);
    });
  });

  group('WeakHashMap iteration', () {
    test('keys, values, entries', () {
      final map = WeakHashMap<TestVal, int>();
      final a = TestVal('a');
      final b = TestVal('b');
      map[a] = 10;
      map[b] = 20;

      expect(map.keys.toSet(), {a, b});
      expect(map.values.toSet(), {10, 20});
      expect(map.entries.length, 2);
    });

    test('updateAll', () {
      final map = WeakHashMap<TestVal, int>();
      final a = TestVal('a');
      final b = TestVal('b');
      final c = TestVal('c');
      map[a] = 1;
      map[b] = 2;
      map[c] = 3;

      map.updateAll((k, v) => v * 2);
      expect(map[a], 2);
      expect(map[b], 4);
    });

    test('map transform', () {
      final map = WeakHashMap<TestVal, int>();
      final a = TestVal('a');
      final b = TestVal('b');
      final c = TestVal('c');
      map[a] = 10;
      map[b] = 20;
      map[c] = 30;

      final mapped = map.map((k, v) => MapEntry(k, v.toString()));
      expect(mapped, {a: '10', b: '20', c: '30'});
    });
  });
}
