import 'package:test/test.dart';
import 'package:weak_collections/weak_collections.dart';

import '../tools.dart';

void main() {
  group('WeakLinkedHashSet', () {
    test('.contains()', () {
      final set = WeakLinkedHashSet<TestVal>();

      final v1 = TestVal('a');
      final v2 = TestVal('b');
      final v3 = TestVal('c');
      final nonExisting = TestVal('d');

      set.addAll([v1, v2, v3]);

      expect(set.length, equals(3));
      expect(set.contains(v1), isTrue);
      expect(set.contains(v2), isTrue);
      expect(set.contains(v3), isTrue);
      expect(set.contains(nonExisting), isFalse);
    });

    test('.contains() with Rewrite equals', () {
      final set = WeakLinkedHashSet<TestEqualsObject>();

      final a = TestEqualsObject('a');
      final b = TestEqualsObject('b');
      final c = TestEqualsObject('c');
      final c2 = TestEqualsObject('c');

      set.addAll([a, b, c]);

      expect(set.length, equals(3));
      expect(set.contains(a), isTrue);
      expect(set.contains(b), isTrue);
      expect(set.contains(c), isTrue);
      expect(set.contains(c2), isTrue);
    });

    test('head and tail', () {
      final set = WeakLinkedHashSet<TestVal>();

      expect(set.headEqNull, isTrue);
      expect(set.tailEqNull, isTrue);
      expect(set.isEmpty, isTrue);

      final a = TestVal('a');
      final b = TestVal('b');
      final c = TestVal('c');

      set.add(a);
      expect(set.headEqNull, isFalse);
      expect(set.tailEqNull, isFalse);
      expect(set.headValue, equals(a));
      expect(set.tailValue, equals(a));
      expect(set.headEqTail, isTrue);

      set.addAll([a, b, c]);
      expect(set.headEqNull, isFalse);
      expect(set.tailEqNull, isFalse);
      expect(set.headValue, equals(a));
      expect(set.tailValue, equals(c));
      expect(set.headEqTail, isFalse);

      set.clear();
      expect(set.isEmpty, isTrue);
      expect(set.headEqNull, isTrue);
      expect(set.tailEqNull, isTrue);
    });

    test('fist and last', () {
      final set = WeakLinkedHashSet<TestVal>();

      expect(set.headEqNull, isTrue);
      expect(set.tailEqNull, isTrue);

      final a = TestVal('a');
      final b = TestVal('b');
      final c = TestVal('c');
      final d = TestVal('d');
      final e = TestVal('e');
      final f = TestVal('f');

      set.addAll([a, b, c]);

      expect(set.first, equals(a));
      expect(set.last, equals(c));
      expect(set.headEqNull, isFalse);
      expect(set.tailEqNull, isFalse);
      expect(set.headValue, equals(a));
      expect(set.tailValue, equals(c));

      set.clear();
      expect(set.isEmpty, isTrue);
      expect(() => set.first, throwsStateError);
      expect(() => set.last, throwsStateError);
      expect(set.headEqNull, isTrue);
      expect(set.tailEqNull, isTrue);

      set.add(d);
      set.add(e);
      set.add(f);
      expect(set.first, equals(d));
      expect(set.last, equals(f));
      expect(set.headEqNull, isFalse);
      expect(set.tailEqNull, isFalse);
      expect(set.headValue, equals(d));
      expect(set.tailValue, equals(f));
    });

    test('.iterator orderedEquals', () {
      final set = WeakLinkedHashSet<TestVal>();

      final a = TestVal('a');
      final b = TestVal('b');
      final c = TestVal('c');

      set.addAll([a, b, c]);
      expect(set.length, equals(3));

      final iterator = set.iterator;
      expect(iterator.moveNext(), isTrue);
      expect(iterator.current, equals(a));
      expect(iterator.moveNext(), isTrue);
      expect(iterator.current, equals(b));
      expect(iterator.moveNext(), isTrue);
      expect(iterator.current, equals(c));
      expect(iterator.moveNext(), isFalse);
    });

    test('.toSet() orderedEquals', () {
      final set = WeakLinkedHashSet<TestVal>();

      final a = TestVal('a');
      final b = TestVal('b');
      final c = TestVal('c');

      set.addAll([a, b, c]);
      expect(set.length, equals(3));

      final set2 = set.toSet();
      expect(set2.length, equals(3));
      expect(set2.contains(a), isTrue);
      expect(set2.contains(b), isTrue);
      expect(set2.contains(c), isTrue);
      expect(set2.contains(TestVal('d')), isFalse);

      expect(set2, isNot(same(set)));
      expect(set2, orderedEquals([a, b, c]));
    });
  });

  group('WeakLinkedHashSet.identity', () {
    test('.contains()', () {
      final set = WeakLinkedHashSet<TestObject>.identity();

      final v1 = TestObject('a');
      final v2 = TestObject('b');
      final v3 = TestObject('c');
      final nonExisting = TestObject('d');

      set.addAll([v1, v2, v3]);

      expect(set.runtimeType, isNot(equals(WeakLinkedHashSet<TestObject>)),
          reason: 'sub class');
      expect(set.length, equals(3));
      expect(set.contains(v1), isTrue);
      expect(set.contains(v2), isTrue);
      expect(set.contains(v3), isTrue);
      expect(set.contains(nonExisting), isFalse);
    });

    test('.contains() with Rewrite equals', () {
      final set = WeakLinkedHashSet<TestEqualsObject>.identity();

      final a = TestEqualsObject('a');
      final b = TestEqualsObject('b');
      final c = TestEqualsObject('c');
      final c2 = TestEqualsObject('c');

      set.addAll([a, b, c]);

      expect(
          set.runtimeType, isNot(equals(WeakLinkedHashSet<TestEqualsObject>)),
          reason: 'sub class');
      expect(set.length, equals(3));
      expect(set.contains(a), isTrue);
      expect(set.contains(b), isTrue);
      expect(set.contains(c), isTrue);
      expect(set.contains(c2), isFalse);
    });
  });
}
