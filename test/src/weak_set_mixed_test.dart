import 'package:test/test.dart';
import 'package:weak_collections/weak_collections.dart';

import '../tools.dart';
import '../vm_tools.dart';

void main() {
  late List objects;
  setUp(() {
    objects = [];
  });

  tearDown(() async {
    await tearDownWaitAllGC();
  });

  group('MixedRefHashSet basic operations', () {
    test('.add(), .addWeak(), and .addStrong()', () {
      final set = MixedRefHashSet<TestVal>();

      final v1 = TestVal('a');
      final v2 = TestVal('b');
      final v3 = TestVal('c');

      set.add(v1); // 默认弱引用
      set.addWeak(v2); // 显式弱引用
      set.addStrong(v3); // 显式强引用

      expect(set.length, equals(3));
      expect(set.contains(v1), isTrue);
      expect(set.contains(v2), isTrue);
      expect(set.contains(v3), isTrue);
      expect(set.contains(TestVal('d')), isFalse);
    });

    test('upgrading weak reference to strong reference', () {
      final set = MixedRefHashSet<TestVal>();

      final v1 = TestVal('a');

      expect(set.addWeak(v1), isTrue);
      // 重复 addWeak 应该返回 false
      expect(set.addWeak(v1), isFalse);

      // 通过 addStrong 升级已有弱引用节点为强引用节点
      expect(set.addStrong(v1), isTrue,
          reason: 'Should return true when upgrading weak to strong');
      // 再次 addStrong 应该返回 false
      expect(set.addStrong(v1), isFalse);
    });

    test('isWeak predicate customization', () {
      final set = MixedRefHashSet<TestVal>(
        isWeak: (element) => element.debugName.startsWith('w'),
      );

      final weakVal = TestVal('w_weak');
      final strongVal = TestVal('s_strong');

      set.add(weakVal);
      set.add(strongVal);

      expect(set.length, equals(2));
      expect(set.contains(weakVal), isTrue);
      expect(set.contains(strongVal), isTrue);
    });

    test('identity constructor', () {
      final set = MixedRefHashSet<TestEqualsObject>.identity();

      final a1 = TestEqualsObject('a');
      final a2 = TestEqualsObject('a');

      set.addWeak(a1);

      expect(set.length, equals(1));
      expect(set.contains(a1), isTrue);
      expect(set.contains(a2), isFalse);
    });

    test('custom constructor', () {
      final set = MixedRefHashSet<TestObject>.custom(
        hashCode: customHashCode,
        equals: customEquals,
      );

      final o1 = TestObject('a');
      final o2 = TestObject('a');

      set.addStrong(o1);

      expect(set.length, equals(1));
      expect(set.contains(o2), isTrue);
    });
  });

  group('MixedRefLinkedHashSet ordering', () {
    test('preserves insertion order', () {
      final set = MixedRefLinkedHashSet<TestVal>();

      final v1 = TestVal('a');
      final v2 = TestVal('b');
      final v3 = TestVal('c');

      set.addWeak(v1);
      set.addStrong(v2);
      set.add(v3);

      expect(set.length, equals(3));
      expect(set.toList(), equals([v1, v2, v3]));
      expect(set.first, equals(v1));
      expect(set.last, equals(v3));
    });
  });

  group('MixedRefHashSet garbage collection', () {
    test('weak entries are collected after GC, strong entries remain',
        () async {
      final set = MixedRefHashSet<TestVal>();

      TestVal? weakObj = TestVal('weak');
      TestVal? strongObj = TestVal('strong');

      set.addWeak(weakObj);
      set.addStrong(strongObj);

      expect(set.length, equals(2));

      final weakRef = WeakReference(weakObj);
      final strongRef = WeakReference(strongObj);

      weakObj = null;
      strongObj = null;

      afterGC(() {
        expect(weakRef.target, isNull, reason: 'weak object should be GC\'d');
        expect(strongRef.target, isNotNull,
            reason: 'strong object should be held strongly by set');

        expect(set.length, equals(1));
        expect(set.contains(strongRef.target!), isTrue);
      });
    });

    test('upgraded strong entries survive GC', () async {
      final set = MixedRefHashSet<TestVal>();

      TestVal? obj = TestVal('upgraded');

      set.addWeak(obj);
      set.addStrong(obj); // 升级为强引用

      expect(set.length, equals(1));

      final objRef = WeakReference(obj);
      obj = null;

      afterGC(() {
        expect(objRef.target, isNotNull,
            reason: 'upgraded strong object should survive GC');
        expect(set.length, equals(1));
      });
    });
  });
}
