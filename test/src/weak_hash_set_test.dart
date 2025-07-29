import 'package:test/test.dart';
import 'package:weak_collections/weak_collections.dart';

import '../tools.dart';

void main() {
  group('WeakHashSet', () {
    test('.contains()', () {
      final set = WeakHashSet<TestVal>();

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

    test('.remove()', () {
      final set = WeakHashSet<TestVal>();

      final v1 = TestVal('a');
      final v2 = TestVal('b');
      final v3 = TestVal('c');

      set.addAll([v1, v2, v3]);

      set.remove(v2);

      expect(set.length, equals(2));
      expect(set.contains(v2), isFalse);
    });
  });

  group('with an empty set', () {
    late Set<TestVal> set;
    late TestVal a;
    setUp(() {
      set = WeakHashSet<TestVal>();
      a = TestVal('a');
    });

    test('length returns 0', () {
      expect(set.length, equals(0));
    });

    test('contains() returns false', () {
      expect(set.contains(a), isFalse);
      expect(set.contains(null), isFalse);
      expect(set.contains('foo'), isFalse);
    });

    test('lookup() returns null', () {
      expect(set.lookup(a), isNull);
      expect(set.lookup(null), isNull);
      expect(set.lookup('foo'), isNull);
    });

    test('toSet() returns an empty set', () {
      expect(set.toSet(), isEmpty);
      expect(set.toSet(), isNot(same(set)));
    });

    test("map() doesn't run on any elements", () {
      expect(set.map(expectAsync1((dynamic _) {}, count: 0)), isEmpty);
    });
  });

  group('with multiple disjoint sets', () {
    late Set<TestVal> set;
    late TestVal a, b, c, d, e, f;
    setUp(() {
      a = TestVal('a');
      b = TestVal('b');
      c = TestVal('c');
      d = TestVal('d');
      e = TestVal('e');
      f = TestVal('f');
      set = WeakHashSet();
      set.addAll([a, b]);
      set.addAll([c, d]);
      set.addAll([e]);
    });

    test('length returns the total length', () {
      expect(set.length, equals(5));
    });

    test('contains() returns whether any set contains the element', () {
      expect(set.contains(a), isTrue);
      expect(set.contains(c), isTrue);
      expect(set.contains(e), isTrue);
      expect(set.contains(f), isFalse);
    });

    test('lookup() returns elements that are in any set', () {
      expect(set.lookup(a), equals(a));
      expect(set.lookup(d), equals(d));
      expect(set.lookup(e), equals(e));
      expect(set.lookup(f), isNull);
    });

    test('toSet() returns the union of all the sets', () {
      expect(set.toSet(), unorderedEquals([a, b, c, d, e]));
      expect(set.toSet(), isNot(same(set)));
    });

    // test('map() maps the elements', () {
    //   expect(set.map((i) => i * 2), unorderedEquals([2, 4, 6, 8, 10]));
    // });
  });

  group('with multiple overlapping sets', () {
    late Set<TestVal> set;
    late TestVal a, b, c, d, e, f;
    setUp(() {
      a = TestVal('a');
      b = TestVal('b');
      c = TestVal('c');
      d = TestVal('d');
      e = TestVal('e');
      f = TestVal('f');
      set = WeakHashSet();
      set.addAll([a, b, c]);
      set.addAll([c, d]);
      set.addAll([e, a]);
    });

    test('length returns the total length', () {
      expect(set.length, equals(5));
    });

    test('contains() returns whether any set contains the element', () {
      expect(set.contains(a), isTrue);
      expect(set.contains(d), isTrue);
      expect(set.contains(e), isTrue);
      expect(set.contains(f), isFalse);
    });

    test('lookup() returns elements that are in any set', () {
      expect(set.lookup(a), equals(a));
      expect(set.lookup(d), equals(d));
      expect(set.lookup(e), equals(e));
      expect(set.lookup(f), isNull);
    });

    test('lookup() returns the first element in an ordered context', () {
      var duration1 = const Duration(seconds: 0);
      // ignore: prefer_const_constructors
      var duration2 = Duration(seconds: 0);
      expect(duration1, equals(duration2));

      expect(duration1, isNot(same(duration2)));

      var set = WeakHashSet();
      set.add(duration1);
      set.addAll({duration2});

      expect(set.lookup(const Duration(seconds: 0)), same(duration1));
    });

    test('toSet() returns the union of all the sets', () {
      expect(set.toSet(), unorderedEquals([a, b, c, d, e]));
      expect(set.toSet(), isNot(same(set)));
    });

    // test('map() maps the elements', () {
    //   expect(set.map((i) => i * 2), unorderedEquals([2, 4, 6, 8, 10]));
    // });
  });

  // group('after an inner set was modified', () {
  //   late Set set;
  //   setUp(() {
  //     var innerSet = {3, 7};
  //     set = UnionSet.from([
  //       {1, 2},
  //       {5},
  //       innerSet,
  //     ]);
  //
  //     innerSet.add(4);
  //     innerSet.remove(7);
  //   });
  //
  //   test('length returns the total length', () {
  //     expect(set.length, equals(5));
  //   });
  //
  //   test('contains() returns true for a new element', () {
  //     expect(set.contains(4), isTrue);
  //   });
  //
  //   test('contains() returns false for a removed element', () {
  //     expect(set.contains(7), isFalse);
  //   });
  //
  //   test('lookup() returns a new element', () {
  //     expect(set.lookup(4), equals(4));
  //   });
  //
  //   test("lookup() doesn't returns a removed element", () {
  //     expect(set.lookup(7), isNull);
  //   });
  //
  //   test('toSet() returns the union of all the sets', () {
  //     expect(set.toSet(), unorderedEquals([1, 2, 3, 4, 5]));
  //     expect(set.toSet(), isNot(same(set)));
  //   });
  //
  //   test('map() maps the elements', () {
  //     expect(set.map((i) => i * 2), unorderedEquals([2, 4, 6, 8, 10]));
  //   });
  // });

  group('after the set was modified', () {
    late Set<TestVal> set;
    late TestVal a, b, c, d, e, f;
    setUp(() {
      a = TestVal('a');
      b = TestVal('b');
      c = TestVal('c');
      d = TestVal('d');
      e = TestVal('e');
      f = TestVal('f');
      set = WeakHashSet();
      set.addAll([a, b, c, e, f]);

      final willRemove = [a, d, f];

      set.removeAll(willRemove);

      set.add(d);
    });

    test('length returns the total length', () {
      expect(set.length, equals(4));
    });

    test('contains() returns true for a new element', () {
      expect(set.contains(d), isTrue);
    });

    test('contains() returns false for a removed element', () {
      expect(set.contains(a), isFalse);
    });

    test('lookup() returns a new element', () {
      expect(set.lookup(d), equals(d));
    });

    test("lookup() doesn't returns a removed element", () {
      expect(set.lookup(f), isNull);
    });

    test('toSet() returns the union of all the sets', () {
      expect(set.toSet(), unorderedEquals([b, c, d, e]));
      expect(set.toSet(), isNot(same(set)));
    });

    // test('map() maps the elements', () {
    //   expect(set.map((i) => i * 2), unorderedEquals([2, 4, 6, 8, 10]));
    // });
  });
}
