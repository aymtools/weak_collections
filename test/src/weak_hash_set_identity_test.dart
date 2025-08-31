import 'package:test/test.dart';
import 'package:weak_collections/weak_collections.dart';

import '../tools.dart';

void main() {
  group('WeakHashSet.identity', () {
    test('.contains()', () {
      final set = WeakHashSet<TestObject>.identity();

      final v1 = TestObject('a');
      final v2 = TestObject('b');
      final v3 = TestObject('c');
      final nonExisting = TestObject('d');

      set.addAll([v1, v2, v3]);

      expect(set.runtimeType, isNot(equals(WeakHashSet<TestObject>)),
          reason: 'sub class');
      expect(set.length, equals(3));
      expect(set.contains(v1), isTrue);
      expect(set.contains(v2), isTrue);
      expect(set.contains(v3), isTrue);
      expect(set.contains(nonExisting), isFalse);
    });

    test('.contains() with Rewrite equals', () {
      final set = WeakHashSet<TestEqualsObject>.identity();

      final a = TestEqualsObject('a');
      final b = TestEqualsObject('b');
      final c = TestEqualsObject('c');
      final c2 = TestEqualsObject('c');

      set.addAll([a, b, c]);

      expect(set.runtimeType, isNot(equals(WeakHashSet<TestEqualsObject>)),
          reason: 'sub class');
      expect(set.length, equals(3));
      expect(set.contains(a), isTrue);
      expect(set.contains(b), isTrue);
      expect(set.contains(c), isTrue);
      expect(set.contains(c2), isFalse);
    });
  });
}
