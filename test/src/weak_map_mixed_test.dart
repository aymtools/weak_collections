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

  group('MixedRefHashMap basic operations', () {
    test('.put(), .putWeakKey(), and .putStrongKey()', () {
      final map = MixedRefHashMap<TestVal, String>();

      final k1 = TestVal('a');
      final k2 = TestVal('b');
      final k3 = TestVal('c');

      map[k1] = 'val1'; // 默认弱引用 Key
      map.putWeakKey(k2, 'val2'); // 显式弱引用 Key
      map.putStrongKey(k3, 'val3'); // 显式强引用 Key

      expect(map.length, equals(3));
      expect(map[k1], equals('val1'));
      expect(map[k2], equals('val2'));
      expect(map[k3], equals('val3'));
      expect(map.containsKey(TestVal('d')), isFalse);
    });

    test('upgrading weak key reference to strong key reference', () {
      final map = MixedRefHashMap<TestVal, String>();

      final k1 = TestVal('a');

      map.putWeakKey(k1, 'weak_val');
      expect(map[k1], equals('weak_val'));

      // 通过 putStrongKey 将已有弱引用 Key 节点升级为强引用 Key
      map.putStrongKey(k1, 'strong_val');
      expect(map[k1], equals('strong_val'));
      expect(map.length, equals(1));
    });

    test('isWeakKey predicate customization', () {
      final map = MixedRefHashMap<TestVal, String>(
        isWeakKey: (key) => key.debugName.startsWith('w'),
      );

      final weakKey = TestVal('w_weak');
      final strongKey = TestVal('s_strong');

      map[weakKey] = 'val_w';
      map[strongKey] = 'val_s';

      expect(map.length, equals(2));
      expect(map[weakKey], equals('val_w'));
      expect(map[strongKey], equals('val_s'));
    });

    test('identity constructor', () {
      final map = MixedRefHashMap<TestEqualsObject, String>.identity();

      final k1 = TestEqualsObject('a');
      final k2 = TestEqualsObject('a');

      map.putWeakKey(k1, 'v1');

      expect(map.length, equals(1));
      expect(map[k1], equals('v1'));
      expect(map[k2], isNull);
    });

    test('custom constructor', () {
      final map = MixedRefHashMap<TestObject, String>.custom(
        hashCode: customHashCode,
        equals: customEquals,
      );

      final o1 = TestObject('a');
      final o2 = TestObject('a');

      map.putStrongKey(o1, 'custom_val');

      expect(map.length, equals(1));
      expect(map[o2], equals('custom_val'));
    });
  });

  group('MixedRefLinkedHashMap ordering', () {
    test('preserves insertion order', () {
      final map = MixedRefLinkedHashMap<TestVal, String>();

      final k1 = TestVal('a');
      final k2 = TestVal('b');
      final k3 = TestVal('c');

      map.putWeakKey(k1, 'v1');
      map.putStrongKey(k2, 'v2');
      map[k3] = 'v3';

      expect(map.length, equals(3));
      expect(map.keys.toList(), equals([k1, k2, k3]));
      expect(map.values.toList(), equals(['v1', 'v2', 'v3']));
    });
  });

  group('MixedRefHashMap garbage collection', () {
    test('putWeakKey entries get collected, putStrongKey entries remain',
        () async {
      final map = MixedRefHashMap<TestVal, String>();

      TestVal? weakKey = TestVal('weak_key');
      TestVal? strongKey = TestVal('strong_key');

      map.putWeakKey(weakKey, 'weak_val');
      map.putStrongKey(strongKey, 'strong_val');

      expect(map.length, equals(2));

      final weakRef = WeakReference(weakKey);
      final strongRef = WeakReference(strongKey);

      weakKey = null;
      strongKey = null;

      afterGC(() {
        expect(weakRef.target, isNull, reason: 'weak key should be GC\'d');
        expect(strongRef.target, isNotNull,
            reason: 'strong key should be held strongly by map');

        expect(map.length, equals(1));
        expect(map[strongRef.target!], equals('strong_val'));
      });
    });

    test('upgraded strong key entries survive GC', () async {
      final map = MixedRefHashMap<TestVal, String>();

      TestVal? key = TestVal('upgraded_key');

      map.putWeakKey(key, 'val');
      map.putStrongKey(key, 'val'); // 升级 Key 为强引用

      expect(map.length, equals(1));

      final keyRef = WeakReference(key);
      key = null;

      afterGC(() {
        expect(keyRef.target, isNotNull,
            reason: 'upgraded strong key should survive GC');
        expect(map.length, equals(1));
      });
    });
  });
}
