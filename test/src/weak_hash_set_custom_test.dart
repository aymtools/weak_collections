import 'package:test/test.dart';
import 'package:weak_collections/weak_collections.dart';

import '../tools.dart';

void main() {
  group('WeakHashSet.custom', () {
    test('.contains()', () {
      final set = WeakHashSet<TestObject>.custom();

      final v1 = TestObject('a');
      final v2 = TestObject('b');
      final v3 = TestObject('c');
      final nonExisting = TestObject('d');

      set.addAll([v1, v2, v3]);

      expect(set.runtimeType, equals(WeakHashSet<TestObject>));
      expect(set.length, equals(3));
      expect(set.contains(v1), isTrue);
      expect(set.contains(v2), isTrue);
      expect(set.contains(v3), isTrue);
      expect(set.contains(nonExisting), isFalse);
    });

    test('.contains() with custom hashCode', () {
      final set = WeakHashSet<TestObject>.custom(
          hashCode: customHashCodeNotAThenRandom);

      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');
      final nonExisting = TestObject('d');

      set.addAll([a, b, c]);

      expect(set.runtimeType, isNot(equals(WeakHashSet<TestObject>)),
          reason: 'sub class');
      expect(set.length, equals(3));
      expect(set.contains(a), isTrue);

      /// 依然会存在一个 1/(bucket.length) 的概率触发 桶碰撞，所以还是有概率 在桶中找到
      expect(set.contains(b), isFalse, reason: 'hash does not exist');
      expect(set.contains(c), isFalse, reason: 'hash does not exist');
      expect(set.contains(nonExisting), isFalse);
    });

    test('.contains() with custom hashCode equals', () {
      final set = WeakHashSet<TestObject>.custom(
          hashCode: customHashCode, equals: customEquals);

      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');
      final c2 = TestObject('c');
      final nonExisting = TestObject('d');

      set.addAll([a, b, c]);
      expect(set.runtimeType, isNot(equals(WeakHashSet<TestObject>)),
          reason: 'sub class');
      expect(set.length, equals(3));
      expect(set.contains(a), isTrue);
      expect(set.contains(b), isTrue);
      expect(set.contains(c), isTrue);
      expect(set.contains(c2), isTrue);
      expect(set.contains(nonExisting), isFalse);
    });

    test('.contains() custom isValidKey', () {
      final set =
          WeakHashSet<TestObject>.custom(isValidKey: customIsValidKeyAdB);

      final a = TestObject('a');
      final b = TestObject('b');
      final c = TestObject('c');
      final b2 = TestObject('b');
      final nonExisting = TestObject('d');

      set.addAll([a, b, c]);

      expect(set.runtimeType, isNot(equals(WeakHashSet<TestObject>)),
          reason: 'sub class');
      expect(set.length, equals(3));
      expect(set.contains(a), isTrue);
      expect(set.contains(b), isTrue);
      expect(set.contains(c), isFalse, reason: 'c isValidKey returns false。');
      expect(set.contains(b2), isFalse);
      expect(set.contains(nonExisting), isFalse);
    });
  });

  test('.contains() custom hashCode equals isValidKey', () {
    final set = WeakHashSet<TestObject>.custom(
        isValidKey: customIsValidKeyAdB,
        hashCode: customHashCode,
        equals: customEquals);

    final a = TestObject('a');
    final b = TestObject('b');
    final c = TestObject('c');
    final b2 = TestObject('b');
    final nonExisting = TestObject('d');

    set.addAll([a, b, c]);

    expect(set.runtimeType, isNot(equals(WeakHashSet<TestObject>)),
        reason: 'sub class');
    expect(set.length, equals(3));
    expect(set.contains(a), isTrue);
    expect(set.contains(b), isTrue);
    expect(set.contains(c), isFalse, reason: 'c isValidKey returns false。');
    expect(set.contains(b2), isTrue);
    expect(set.contains(nonExisting), isFalse);
  });
}
