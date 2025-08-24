import 'package:test/test.dart';
import 'package:weak_collections/weak_collections.dart';

import 'tools.dart';
import 'vm_tools.dart';

void main() {
  late List<Future> futures;
  late List objects;
  setUp(() {
    futures = [];
    objects = [];
  });

  tearDown(() async {
    // final list = List.filled(102000000, () => Object());
    // await waiteGC(list);
    await Future.wait(futures);
  });

  group('WeakHashMap garbage collection', () {
    test('entry should be collected after GC', () async {
      final map = WeakHashMap<TestVal, String>();

      TestVal? a = TestVal('a');
      map[a] = 'hello';
      expect(map.containsKey(a), isTrue);
      expect(map.isNotEmpty, isTrue);

      // 强制 GC
      futures.add(
        waiteGC(a).then((_) {
          expect(map.isEmpty, isTrue);
          expect(map.containsValue('hello'), isFalse);
        }),
      );
      // 删除强引用
      a = null;
    });

    test('MapEntry should be collected after GC', () async {
      Map<TestVal, String>? map = WeakHashMap<TestVal, String>();

      TestVal a = TestVal('a');
      map[a] = 'hello';
      expect(map.containsKey(a), isTrue);
      expect(map.isNotEmpty, isTrue);

      final entity = WeakReference(map.entries.first);
      expect(entity.target, isNotNull);
      final aWeak = WeakReference(a);
      expect(aWeak.target, isNotNull);

      objects.add(a);
      // 强制 GC
      futures.add(
        waiteGC(map).then((_) {
          expect(entity.target, isNull);
          expect(aWeak, isNotNull);
          expect(aWeak.target, isNotNull, reason: 'objects ref');
        }),
      );
      // 删除强引用
      map = null;
    });
  });

  group('WeakHashSet garbage collection', () {
    test('entry should be collected after GC', () {
      final set = WeakHashSet<TestVal>();

      TestVal? a = TestVal('a');
      set.add(a);

      expect(set.contains(a), isTrue);
      expect(set.isNotEmpty, isTrue);

      // 强制 GC
      futures.add(
        waiteGC(a).then((_) {
          expect(set.isEmpty, isTrue);
        }),
      );
      // 删除强引用
      a = null;
    });

    test('SetEntry should be collected after GC', () async {
      Set<TestVal>? set = WeakHashSet<TestVal>();

      TestVal a = TestVal('a');
      set.add(a);

      expect(set.contains(a), isTrue);
      expect(set.isNotEmpty, isTrue);

      final aWeak = WeakReference(a);
      expect(aWeak.target, isNotNull);

      // 强制 GC
      futures.add(
        waiteGC(set).then((_) {
          expect(aWeak.target, isNull);
        }),
      );
      // 删除强引用
      set = null;
    });
  });

  group('WeakQueue garbage collection', () {
    test('entry should be collected after GC', () async {
      final queue = WeakQueue<TestVal>();

      TestVal? a = TestVal('a');
      queue.add(a);

      expect(queue.contains(a), isTrue);
      expect(queue.isNotEmpty, isTrue);

      // 强制 GC
      futures.add(
        waiteGC(a).then((_) {
          expect(queue.isEmpty, isTrue);
        }),
      );
      // 删除强引用
      a = null;
    });
  });
}
