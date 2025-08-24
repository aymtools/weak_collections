import 'package:test/test.dart';
import 'package:weak_collections/weak_collections.dart';

import 'tools.dart';
import 'vm_tools.dart';

void main() {
  late List objects;
  setUp(() {
    objects = [];
  });

  tearDown(() async {
    await tearDownWaitAllGC();
  });

  group('WeakHashMap garbage collection', () {
    test('entry should be collected after GC', () async {
      final map = WeakHashMap<TestVal, String>();

      TestVal? a = TestVal('a');
      map[a] = 'hello';
      expect(map.containsKey(a), isTrue);
      expect(map.isNotEmpty, isTrue);

      final entry = WeakReference(map.getWeakEntry(a)!);
      expect(entry.target, isNotNull);
      final aWeak = WeakReference(a);
      expect(aWeak.target, isNotNull);

      // 强制  GC
      afterGC(() {
        expect(map.isEmpty, isTrue);
        expect(map.containsValue('hello'), isFalse);

        // 需要等待 entry 也没有引用了才能执行
        afterGC(() {
          expect(entry.target, isNull);
          expect(aWeak.target, isNull);
        });
      });
      // 删除强引用
      a = null;
    });

    test('MapEntry should be collected after GC', () async {
      WeakHashMap<TestVal, String>? map = WeakHashMap();

      TestVal a = TestVal('a');
      map[a] = 'hello';
      expect(map.containsKey(a), isTrue);
      expect(map.isNotEmpty, isTrue);

      final entry = WeakReference(map.getWeakEntry(a)!);
      expect(entry.target, isNotNull);
      final aWeak = WeakReference(a);
      expect(aWeak.target, isNotNull);

      objects.add(a);
      // 强制 GC
      afterGC(() {
        expect(entry.target, isNull);
        expect(aWeak, isNotNull);
        expect(aWeak.target, isNotNull, reason: 'objects ref');
      });
      // 删除强引用
      map = null;
    });

    test('remove should be collected after GC', () async {
      final map = WeakHashMap<TestVal, String>();

      TestVal? a = TestVal('a');
      map[a] = 'hello';
      expect(map.containsKey(a), isTrue);
      expect(map.isNotEmpty, isTrue);

      final entry = WeakReference(map.getWeakEntry(a)!);
      expect(entry.target, isNotNull);
      final aWeak = WeakReference(a);
      expect(aWeak.target, isNotNull);

      map.remove(a);
      expect(map.containsKey(a), isFalse);
      expect(map.isEmpty, isTrue);

      objects.add(map);
      // 强制 GC
      afterGC(() {
        expect(entry.target, isNull);
        expect(aWeak, isNotNull);
        expect(aWeak.target, isNull);
      });
      // 删除强引用
      a = null;
    });
  });

  group('WeakHashSet garbage collection', () {
    test('entry should be collected after GC', () {
      WeakHashSet<TestVal> set = WeakHashSet<TestVal>();

      TestVal? a = TestVal('a');
      set.add(a);

      expect(set.contains(a), isTrue);
      expect(set.isNotEmpty, isTrue);

      final entry = WeakReference(set.getWeakEntry(a)!);
      expect(entry.target, isNotNull);

      // 强制 GC
      afterGC(() {
        expect(set.isEmpty, isTrue);
        // 需要等待 entry 也没有引用了才能执行
        afterGC(() {
          expect(entry.target, isNull);
        });
      });
      // 删除强引用
      a = null;
    });

    test('SetEntry should be collected after GC', () async {
      WeakHashSet<TestVal>? set = WeakHashSet();

      TestVal a = TestVal('a');
      set.add(a);

      expect(set.contains(a), isTrue);
      expect(set.isNotEmpty, isTrue);

      final aWeak = WeakReference(a);
      expect(aWeak.target, isNotNull);
      final entry = WeakReference(set.getWeakEntry(a)!);
      expect(entry.target, isNotNull);

      // 强制 GC
      afterGC(() {
        expect(aWeak.target, isNull);
        expect(entry.target, isNull);
      });
      // 删除强引用
      set = null;
    });

    test('remove should be collected after GC', () async {
      WeakHashSet<TestVal> set = WeakHashSet<TestVal>();

      TestVal? a = TestVal('a');
      set.add(a);

      expect(set.contains(a), isTrue);
      expect(set.isNotEmpty, isTrue);

      final entry = WeakReference(set.getWeakEntry(a)!);
      expect(entry.target, isNotNull);
      set.remove(a);

      // 强制 GC
      afterGC(() {
        expect(set.isEmpty, isTrue);
        expect(entry.target, isNull);
      });
      // 删除强引用
      a = null;
    });
  });

  group('WeakQueue garbage collection', () {
    test('entry should be collected after GC', () async {
      final queue = WeakQueue<TestVal>();

      TestVal? a = TestVal('a');
      queue.add(a);

      expect(queue.contains(a), isTrue);
      expect(queue.isNotEmpty, isTrue);

      final entry = WeakReference(queue.getWeakEntry(a)!);
      expect(entry.target, isNotNull);

      // 强制 GC
      afterGC(() {
        expect(queue.isEmpty, isTrue);

        expect(entry.target, isNotNull,
            reason: 'entry has not been released yet');
        afterGC(() {
          expect(entry.target, isNull);
        });
      });
      // 删除强引用
      a = null;
    });

    test('QueueEntry should be collected after GC', () async {
      WeakQueue<TestVal>? queue = WeakQueue<TestVal>();

      TestVal? a = TestVal('a');
      queue.add(a);

      expect(queue.contains(a), isTrue);
      expect(queue.isNotEmpty, isTrue);

      final entry = WeakReference(queue.getWeakEntry(a)!);
      expect(entry.target, isNotNull);
      final aWeak = WeakReference(a);
      expect(aWeak.target, isNotNull);

      objects.add(a);

      // 强制 GC
      afterGC(() {
        expect(aWeak.target, isNotNull);
        expect(entry.target, isNull);
      });
      // 删除强引用
      queue = null;
    });

    test('remove should be collected after GC', () async {
      final queue = WeakQueue<TestVal>();

      TestVal? a = TestVal('a');
      queue.add(a);

      expect(queue.contains(a), isTrue);
      expect(queue.isNotEmpty, isTrue);

      final entry = WeakReference(queue.getWeakEntry(a)!);
      expect(entry.target, isNotNull);
      final aWeak = WeakReference(a);
      expect(aWeak.target, isNotNull);

      queue.remove(a);
      expect(queue.contains(a), isFalse);
      expect(queue.isEmpty, isTrue);

      objects.add(queue);
      // 强制 GC
      afterGC(() {
        expect(entry.target, isNull);
      });
      // 删除强引用
      a = null;
    });
  });
}
