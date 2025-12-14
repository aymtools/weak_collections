import 'package:test/test.dart';
import 'package:weak_collections/weak_collections.dart';

import '../tools.dart';

void main() {
  group('WeakLinkedHashMap', () {
    test('.contains()', () {
      final map = WeakLinkedHashMap<TestVal, String>();

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
      final map = WeakLinkedHashMap<TestEqualsObject, String>();

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
    test('head and tail', () {
      final map = WeakLinkedHashMap<TestEqualsObject, String>();
      expect(map.headEqNull, isTrue);
      expect(map.tailEqNull, isTrue);
      expect(map.isEmpty, isTrue);

      final a = TestEqualsObject('a');
      final b = TestEqualsObject('b');
      final c = TestEqualsObject('c');

      map[a] = 'a';
      expect(map.headEqNull, isFalse);
      expect(map.tailEqNull, isFalse);
      expect(map.headKey, equals(a));
      expect(map.tailKey, equals(a));
      expect(map.headEqTail, isTrue);
      expect(map.headValue, equals('a'));
      expect(map.tailValue, equals('a'));
      expect(map.length, equals(1));
      expect(map.containsKey(a), isTrue);
      expect(map.containsValue('a'), isTrue);

      map[a] = 'a1';
      map[b] = 'b';
      map[c] = 'c';

      expect(map.headEqNull, isFalse);
      expect(map.tailEqNull, isFalse);
      expect(map.headKey, equals(a));
      expect(map.tailKey, equals(c));
      expect(map.headEqTail, isFalse);
      expect(map.headValue, equals('a1'));
      expect(map.tailValue, equals('c'));
      expect(map.length, equals(3));

      map.clear();
      expect(map.isEmpty, isTrue);
      expect(map.headEqNull, isTrue);
      expect(map.tailEqNull, isTrue);
      expect(map.headKey, isNull);
      expect(map.tailKey, isNull);
    });

    test('.iterator orderedEquals', () {
      final map = WeakLinkedHashMap<TestEqualsObject, String>();

      final a = TestEqualsObject('a');
      final b = TestEqualsObject('b');
      final c = TestEqualsObject('c');
      final c2 = TestEqualsObject('c');
      final d = TestEqualsObject('d');
      final e = TestEqualsObject('e');
      final f = TestEqualsObject('f');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';
      expect(map.length, equals(3));

      expect(map.keys, orderedEquals([a, b, c]));
      expect(map.values, orderedEquals(['a', 'b', 'c']));

      map.clear();
      expect(map.isEmpty, isTrue);
      expect(map.keys, isEmpty);
      expect(map.values, isEmpty);

      map[d] = 'd';
      map[e] = 'e';
      map[f] = 'f';

      expect(map.length, equals(3));
      expect(map.keys, orderedEquals([d, e, f]));
      expect(map.values, orderedEquals(['d', 'e', 'f']));
    });

    test('.entries orderedEquals', () {
      final map = WeakLinkedHashMap<TestEqualsObject, String>();

      final a = TestEqualsObject('a');
      final b = TestEqualsObject('b');
      final c = TestEqualsObject('c');
      final c2 = TestEqualsObject('c');
      final d = TestEqualsObject('d');
      final e = TestEqualsObject('e');
      final f = TestEqualsObject('f');

      map[a] = 'a';
      map[b] = 'b';
      map[c] = 'c';
      expect(map.length, equals(3));

      final entries = map.entries;
      expect(entries, isNotEmpty);
      final iterator = entries.iterator;
      expect(iterator.moveNext(), isTrue);
      expect(iterator.current.key, equals(a));
      expect(iterator.current.value, equals('a'));
      expect(iterator.moveNext(), isTrue);
      expect(iterator.current.key, equals(b));
      expect(iterator.current.value, equals('b'));
      expect(iterator.moveNext(), isTrue);
      expect(iterator.current.key, equals(c));
      expect(iterator.current.value, equals('c'));
      expect(iterator.moveNext(), isFalse);

      map.clear();
      expect(map.isEmpty, isTrue);
      expect(map.entries, isEmpty);

      map[d] = 'd';
      map[e] = 'e';
      map[f] = 'f';

      final entries2 = map.entries;
      expect(map.length, equals(3));
      expect(entries2, isNotEmpty);

      final iterator2 = entries2.iterator;
      expect(iterator2.moveNext(), isTrue);
      expect(iterator2.current.key, equals(d));
      expect(iterator2.current.value, equals('d'));
      expect(iterator2.moveNext(), isTrue);
      expect(iterator2.current.key, equals(e));
      expect(iterator2.current.value, equals('e'));
      expect(iterator2.moveNext(), isTrue);
      expect(iterator2.current.key, equals(f));
      expect(iterator2.current.value, equals('f'));
      expect(iterator2.moveNext(), isFalse);
    });
  });
}
