import 'package:test/test.dart';
import 'package:weak_collections/weak_collections.dart';

import '../tools.dart';

void main() {
  group('WeakHashMap.identity', () {
    test('.contains()', () {
      final map = WeakHashMap<TestObject, String>.identity();

      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');
      final nonExisting = TestObject('d');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';

      expect(map.runtimeType, isNot(equals(WeakHashMap<TestObject, String>)),
          reason: 'sub class');
      expect(map.length, equals(3));
      expect(map.containsKey(a), isTrue);
      expect(map.containsKey(b), isTrue);
      expect(map.containsKey(c), isTrue);
      expect(map.containsValue('c'), isTrue);
      expect(map.containsKey(nonExisting), isFalse);
    });
    test('.contains() with Rewrite equals', () {
      final map = WeakHashMap<TestEqualsObject, String>.identity();

      final a = TestEqualsObject('a');
      final b = TestEqualsObject('b');
      final c = TestEqualsObject('c');
      final nonExisting = TestEqualsObject('d');
      final c2 = TestEqualsObject('c');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';

      expect(
          map.runtimeType, isNot(equals(WeakHashMap<TestEqualsObject, String>)),
          reason: 'sub class');
      expect(map.length, equals(3));
      expect(map.containsKey(a), isTrue);
      expect(map.containsKey(b), isTrue);
      expect(map.containsKey(c), isTrue);
      expect(map.containsKey(c2), isFalse);
      expect(map.containsValue('c'), isTrue);
      expect(map.containsKey(nonExisting), isFalse);
    });

    test('.get()', () {
      final map = WeakHashMap<TestObject, String>.identity();

      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');
      final nonExisting = TestObject('d');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';

      expect(map.runtimeType, isNot(equals(WeakHashMap<TestObject, String>)),
          reason: 'sub class');
      expect(map.length, equals(3));
      expect(map.containsKey(a), isTrue);
      expect(map.containsKey(b), isTrue);
      expect(map.containsKey(c), isTrue);
      expect(map.containsValue('c'), isTrue);
      expect(map.containsKey(nonExisting), isFalse);

      expect(map[a], 'a');
      expect(map[b], 'b');
      expect(map[c], 'c');
      expect(map[nonExisting], isNull);
    });

    test('.get() with Rewrite equals', () {
      final map = WeakHashMap<TestEqualsObject, String>.identity();

      final a = TestEqualsObject('a');
      final b = TestEqualsObject('b');
      final c = TestEqualsObject('c');
      final c2 = TestEqualsObject('c');
      final nonExisting = TestEqualsObject('d');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';

      expect(
          map.runtimeType, isNot(equals(WeakHashMap<TestEqualsObject, String>)),
          reason: 'sub class');
      expect(map.length, equals(3));
      expect(map.containsKey(a), isTrue);
      expect(map.containsKey(b), isTrue);
      expect(map.containsKey(c), isTrue);
      expect(map.containsValue('c'), isTrue);
      expect(map.containsKey(c2), isFalse);
      expect(map.containsKey(nonExisting), isFalse);

      expect(map[a], 'a');
      expect(map[b], 'b');
      expect(map[c], 'c');
      expect(map[c2], isNull);
      expect(map[nonExisting], isNull);
    });

    test('.remove()', () {
      final map = WeakHashMap<TestObject, String>.identity();

      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';

      final v = map.remove(b);

      expect(v, 'b');

      expect(map.runtimeType, isNot(equals(WeakHashMap<TestObject, String>)),
          reason: 'sub class');
      expect(map.length, equals(2));
      expect(map.containsKey(b), isFalse);
      expect(map.containsValue('b'), isFalse);
    });

    test('.remove() with Rewrite equals', () {
      final map = WeakHashMap<TestEqualsObject, String>.identity();

      final a = TestEqualsObject('a');
      final b = TestEqualsObject('b');
      final c = TestEqualsObject('c');
      final c2 = TestEqualsObject('c');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';

      map.remove(c2);

      expect(
          map.runtimeType, isNot(equals(WeakHashMap<TestEqualsObject, String>)),
          reason: 'sub class');
      expect(map.length, equals(3));
      expect(map.containsKey(b), isTrue);
      expect(map.containsKey(c), isTrue);
      expect(map.containsValue('c'), isTrue);
    });

    test('.put()', () {
      final map = WeakHashMap<TestObject, String>.identity();

      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';
      map[c] = 'c next';

      expect(map.runtimeType, isNot(isA<WeakHashMap<TestObject, String>>()),
          reason: 'sub class');

      expect(map.length, equals(3));
      expect(map.containsKey(c), isTrue);
      expect(map.containsValue('c'), isFalse);
      expect(map.containsValue('c next'), isTrue);
    });

    test('.put() with Rewrite equals', () {
      final map = WeakHashMap<TestEqualsObject, String>.identity();

      final a = TestEqualsObject('a');
      final b = TestEqualsObject('b');
      final c = TestEqualsObject('c');
      final c2 = TestEqualsObject('c');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';

      map[c2] = 'd';

      expect(
          map.runtimeType, isNot(isA<WeakHashMap<TestEqualsObject, String>>()),
          reason: 'sub class');

      expect(map.length, equals(4));
      expect(map.containsKey(b), isTrue);

      expect(map.containsKey(c), isTrue);
      expect(map.containsValue('c'), isTrue);

      expect(map.containsKey(c2), isTrue);
      expect(map.containsValue('d'), isTrue);
    });
  });
}
