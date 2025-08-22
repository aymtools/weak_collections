import 'dart:async';

import 'package:test/test.dart';
import 'package:weak_collections/weak_collections.dart';

import 'tools.dart';

void main() {
  group('WeakHashMap garbage collection', () {
    test('entry should be collected after GC', () async {
      final map = WeakHashMap<TestVal, String>();

      TestVal? a = TestVal('a');
      map[a] = 'hello';

      expect(map.containsKey(a), isTrue);
      expect(map.isNotEmpty, isTrue);

      // 强制 GC
      waiteGC(a).then((_) {
        expect(map.isEmpty, isTrue);
        expect(map.containsValue('hello'), isFalse);
      });
      await Future.delayed(Duration.zero);
      // 删除强引用
      a = null;
    });
  });

  group('WeakHashSet garbage collection', () {
    test('entry should be collected after GC', () async {
      final set = WeakHashSet<TestVal>();

      TestVal? a = TestVal('a');
      set.add(a);

      expect(set.contains(a), isTrue);
      expect(set.isNotEmpty, isTrue);

      // 强制 GC
      waiteGC(a).then((_) {
        expect(set.isEmpty, isTrue);
      });
      await Future.delayed(Duration.zero);
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

      // 强制 GC
      waiteGC(a).then((_) {
        expect(queue.isEmpty, isTrue);
      });
      await Future.delayed(Duration.zero);
      // 删除强引用
      a = null;
    });
  });
}

Future<void> waiteGC(Object check) {
  Completer<void> finalizerCompleter = Completer();
  void call() async {
    // 等待执行完 相关的 finalizer
    await Future.delayed(Duration.zero);
    finalizerCompleter.complete();
  }

  Finalizer<int> finalizer = Finalizer((_) => call());
  finalizer.attach(check, 1);
  return finalizerCompleter.future;
}
