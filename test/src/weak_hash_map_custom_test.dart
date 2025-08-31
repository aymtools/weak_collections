import 'package:test/test.dart';
import 'package:weak_collections/weak_collections.dart';

import '../tools.dart';

void main() {
  group('WeakHashMap.custom', () {
    test('.contains()', () {
      final map = WeakHashMap<TestObject, String>.custom();

      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');
      final nonExisting = TestObject('d');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';

      expect(map.runtimeType, equals(WeakHashMap<TestObject, String>));
      expect(map.length, equals(3));
      expect(map.containsKey(a), isTrue);
      expect(map.containsKey(b), isTrue);
      expect(map.containsKey(c), isTrue);
      expect(map.containsValue('c'), isTrue);
      expect(map.containsKey(nonExisting), isFalse);
    });

    test('.contains() with custom hashCode', () {
      final map = WeakHashMap<TestObject, String>.custom(
          hashCode: customHashCodeNotAThenRandom);

      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');
      final nonExisting = TestObject('d');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';

      expect(map.runtimeType, isNot(equals(WeakHashMap<TestObject, String>)));
      expect(map.length, equals(3));
      expect(map.containsKey(a), isTrue);

      /// 依然会存在一个 1/(bucket.length) 的概率触发 桶碰撞，所以还是有概率 在桶中找到
      expect(map.containsKey(b), isFalse, reason: 'hash does not exist');
      expect(map.containsKey(c), isFalse, reason: 'hash does not exist');
      expect(map.containsValue('c'), isTrue);
      expect(map.containsKey(nonExisting), isFalse);
    });

    test('.contains() with custom hashCode equals', () {
      final map = WeakHashMap<TestObject, String>.custom(
          hashCode: customHashCode, equals: customEquals);
      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');
      final c2 = TestObject('c');
      final nonExisting = TestObject('d');
      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';
      expect(map.runtimeType, isNot(equals(WeakHashMap<TestObject, String>)));
      expect(map.length, equals(3));
      expect(map.containsKey(a), isTrue);
      expect(map.containsKey(b), isTrue);
      expect(map.containsKey(c), isTrue);
      expect(map.containsKey(c2), isTrue);
      expect(map.containsValue('c'), isTrue);
      expect(map.containsKey(nonExisting), isFalse);
    });

    test('.contains() custom isValidKey', () {
      final map = WeakHashMap<TestObject, String>.custom(
          isValidKey: customIsValidKeyAdB);
      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');
      final b2 = TestObject('b');
      final nonExisting = TestObject('d');
      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';

      expect(map.runtimeType, isNot(equals(WeakHashMap<TestObject, String>)));
      expect(map.length, equals(3));
      expect(map.containsKey(a), isTrue);
      expect(map.containsKey(b), isTrue);
      expect(map.containsKey(c), isFalse,
          reason: 'c isValidKey returns false。');
      expect(map.containsKey(b2), isFalse, reason: 'not equals');
      expect(map.containsValue('c'), isTrue);
      expect(map.containsKey(nonExisting), isFalse);
    });

    test('.contains() custom hashCode equals isValidKey', () {
      final map = WeakHashMap<TestObject, String>.custom(
          isValidKey: customIsValidKeyAdB,
          hashCode: customHashCode,
          equals: customEquals);
      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');
      final b2 = TestObject('b');
      final nonExisting = TestObject('d');
      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';
      expect(map.runtimeType, isNot(equals(WeakHashMap<TestObject, String>)));
      expect(map.length, equals(3));
      expect(map.containsKey(a), isTrue);
      expect(map.containsKey(b), isTrue);
      expect(map.containsKey(c), isFalse,
          reason: 'c isValidKey returns false。');
      expect(map.containsKey(b2), isTrue, reason: ' equals');
      expect(map.containsValue('b'), isTrue);
      expect(map.containsValue('c'), isTrue);
      expect(map.containsKey(nonExisting), isFalse);
    });

    test('.get() with custom hashCode', () {
      final map = WeakHashMap<TestObject, String>.custom(
          hashCode: customHashCodeNotAThenRandom);

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
      expect(map[a], 'a');
      expect(map[b], isNull);
      expect(map[c], isNull);
      expect(map.containsValue('c'), isTrue);
      expect(map.containsKey(nonExisting), isFalse);
      expect(map[nonExisting], isNull);
    });

    test('.get() with custom hashCode equals', () {
      final map = WeakHashMap<TestObject, String>.custom(
          hashCode: customHashCode, equals: customEquals);

      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');
      final nonExisting = TestObject('d');
      final b2 = TestObject('b');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';

      expect(map.runtimeType, isNot(equals(WeakHashMap<TestObject, String>)),
          reason: 'sub class');
      expect(map.length, equals(3));
      expect(map[a], 'a');
      expect(map[b], 'b');
      expect(map[c], 'c');
      expect(map[b2], 'b');
      expect(map.containsValue('c'), isTrue);
      expect(map.containsKey(nonExisting), isFalse);
      expect(map[nonExisting], isNull);
    });

    test('.get() custom isValidKey', () {
      final map = WeakHashMap<TestObject, String>.custom(
          isValidKey: customIsValidKeyAdB);
      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');
      final b2 = TestObject('b');
      final nonExisting = TestObject('d');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';

      expect(map.runtimeType, isNot(equals(WeakHashMap<TestObject, String>)),
          reason: 'sub class');
      expect(map.length, equals(3));
      expect(map[a], 'a');
      expect(map[b], 'b');
      expect(map[c], isNull, reason: 'c isValidKey returns false。');
      expect(map[b2], isNull);
      expect(map.containsValue('c'), isTrue);
      expect(map.containsKey(nonExisting), isFalse);
    });

    test('.get() custom hashCode equals isValidKey', () {
      final map = WeakHashMap<TestObject, String>.custom(
          isValidKey: customIsValidKeyAdB,
          hashCode: customHashCode,
          equals: customEquals);
      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');
      final b2 = TestObject('b');
      final nonExisting = TestObject('d');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';

      expect(map.runtimeType, isNot(equals(WeakHashMap<TestObject, String>)),
          reason: 'sub class');

      expect(map.length, equals(3));
      expect(map[a], 'a');
      expect(map[b], 'b');
      expect(map[c], isNull, reason: 'c isValidKey returns false。');
      expect(map[b2], 'b');
      expect(map.containsValue('c'), isTrue);
      expect(map.containsKey(nonExisting), isFalse);
    });

    test('.remove() with custom hashCode', () {
      final map = WeakHashMap<TestObject, String>.custom(
          hashCode: customHashCodeNotAThenRandom);
      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');
      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';
      map.remove(b);

      expect(map.runtimeType, isNot(equals(WeakHashMap<TestObject, String>)),
          reason: 'sub class');
      expect(map.length, equals(3));
      expect(map.containsKey(a), isTrue);
      expect(map.containsKey(b), isFalse, reason: 'hash does not exist');
      expect(map.containsValue('b'), isTrue);
      expect(map.containsKey(c), isFalse, reason: 'hash does not exist');
    });

    test('.remove() with custom hashCode equals', () {
      final map = WeakHashMap<TestObject, String>.custom(
          hashCode: customHashCode, equals: customEquals);
      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');
      final c2 = TestObject('c');
      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';
      map.remove(c2);
      expect(map.runtimeType, isNot(equals(WeakHashMap<TestObject, String>)),
          reason: 'sub class');
      expect(map.length, equals(2));
      expect(map.containsKey(a), isTrue);
      expect(map.containsKey(b), isTrue);
      expect(map.containsKey(c), isFalse);
      expect(map.containsValue('c'), isFalse);
      expect(map.containsKey(c2), isFalse);
    });

    test('.remove() custom isValidKey', () {
      final map = WeakHashMap<TestObject, String>.custom(
          isValidKey: customIsValidKeyAdB);
      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');
      final nonExisting = TestObject('d');
      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';
      map.remove(c);

      expect(map.runtimeType, isNot(equals(WeakHashMap<TestObject, String>)),
          reason: 'sub class');
      expect(map.length, equals(3));
      expect(map.containsKey(a), isTrue);
      expect(map.containsKey(b), isTrue);
      expect(map.containsKey(c), isFalse,
          reason: 'c isValidKey returns false。');
      expect(map.containsValue('c'), isTrue);
      expect(map.containsKey(nonExisting), isFalse);

      map.remove(b);
      expect(map.length, equals(2));
      expect(map.containsKey(b), isFalse, reason: 'removed');
      expect(map.containsValue('b'), isFalse);
    });

    test('.remove() custom hashCode equals isValidKey', () {
      final map = WeakHashMap<TestObject, String>.custom(
          isValidKey: customIsValidKeyAdB,
          hashCode: customHashCode,
          equals: customEquals);
      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');
      final nonExisting = TestObject('d');

      final b2 = TestObject('b');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';

      map.remove(c);
      expect(map.runtimeType, isNot(equals(WeakHashMap<TestObject, String>)),
          reason: 'sub class');
      expect(map.length, equals(3));
      expect(map.containsKey(a), isTrue);
      expect(map.containsKey(b), isTrue);
      expect(map.containsKey(c), isFalse,
          reason: 'c isValidKey returns false。');
      expect(map.containsValue('c'), isTrue);
      expect(map.containsKey(nonExisting), isFalse);

      map.remove(a);
      expect(map.length, equals(2));
      expect(map.containsKey(a), isFalse, reason: 'removed');
      expect(map.containsValue('a'), isFalse);

      map.remove(b2);
      expect(map.length, equals(1));
      expect(map.containsKey(b), isFalse, reason: 'removed');
      expect(map.containsValue('b'), isFalse);

      expect(map.containsValue('c'), isTrue);
    });

    test('.put() with custom hashCode equals', () {
      final map = WeakHashMap<TestObject, String>.custom(
          hashCode: customHashCode, equals: customEquals);
      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');
      final c2 = TestObject('c');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';

      map[c2] = 'd';
      expect(map.runtimeType, isNot(equals(WeakHashMap<TestObject, String>)),
          reason: 'sub class');
      expect(map.length, equals(3));
      expect(map.containsKey(a), isTrue);
      expect(map.containsKey(b), isTrue);
      expect(map.containsKey(c), isTrue);
      expect(map.containsValue('a'), isTrue);
      expect(map.containsValue('b'), isTrue);
      expect(map.containsValue('c'), isFalse);
      expect(map.containsValue('d'), isTrue);
      expect(map.containsKey(c2), isTrue);
    });

    test('.put() custom isValidKey', () {
      final map = WeakHashMap<TestObject, String>.custom(
          isValidKey: customIsValidKeyAdB);
      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';
      map[c] = 'd';
      expect(map.runtimeType, isNot(equals(WeakHashMap<TestObject, String>)),
          reason: 'sub class');
      expect(map.length, equals(3));
      expect(map.containsKey(a), isTrue);
      expect(map.containsKey(b), isTrue);
      expect(map.containsKey(c), isFalse,
          reason: 'c isValidKey returns false。');
      expect(map.containsValue('a'), isTrue);
      expect(map.containsValue('b'), isTrue);
      expect(map.containsValue('c'), isFalse);
      expect(map.containsValue('d'), isTrue);
    });

    test('.put() custom hashCode equals isValidKey', () {
      final map = WeakHashMap<TestObject, String>.custom(
          isValidKey: customIsValidKeyAdB,
          hashCode: customHashCode,
          equals: customEquals);
      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');
      final c2 = TestObject('c');
      final b2 = TestObject('b');
      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';
      map[b2] = 'b';
      map[c2] = 'd';
      expect(map.runtimeType, isNot(equals(WeakHashMap<TestObject, String>)),
          reason: 'sub class');
      expect(map.length, equals(3));
      expect(map.containsKey(a), isTrue);
      expect(map.containsKey(b), isTrue);
      expect(map.containsKey(c), isFalse,reason: 'c isValidKey returns false。');
      expect(map.containsKey(b2), isTrue);
      expect(map.containsValue('a'), isTrue);
      expect(map.containsValue('b'), isTrue);
      expect(map.containsValue('c'), isFalse);
      expect(map.containsValue('d'), isTrue);
    });
  });
}
