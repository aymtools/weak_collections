import 'package:test/test.dart';
import 'package:weak_collections/src/tools.dart';

import '../tools.dart';
import '../vm_tools.dart';

class FinalizationToken {
  final String data;

  FinalizationToken(this.data);

  @override
  String toString() => 'FinalizationToken(data: $data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinalizationToken &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}

void main() {
  late List objects;
  setUp(() {
    objects = [];
  });

  tearDown(() async {
    await tearDownWaitAllGC();
  });

  group('WeakReferenceQueue', () {
    late WeakReferenceQueue<TestObject, FinalizationToken> queue;
    late List<FinalizationToken> finalizedTokens;

    void visitCallback(FinalizationToken token) {
      finalizedTokens.add(token);
    }

    setUp(() {
      queue = WeakReferenceQueue<TestObject, FinalizationToken>();
      finalizedTokens = [];
    });

    test('isEmpty and isNotEmpty reflect queue state', () {
      expect(queue.isEmpty, isTrue);
      expect(queue.isNotEmpty, isFalse);
    });

    test('clear makes the queue empty', () async {
      TestObject? obj1 = TestObject('obj1');
      var token1 = FinalizationToken('token1');
      var weakRef1 = WeakReference(obj1);

      objects.add(token1);
      objects.add(queue);
      queue.attach(weakRef1, token1);

      afterGC(() {
        expect(queue.isNotEmpty, isTrue);
        queue.clear();
        expect(queue.isEmpty, isTrue);
        expect(queue.isNotEmpty, isFalse);
      });

      obj1 = null;
    });

    // test('attach and detach affect Finalizer (conceptual test)', () async {
    //   // This test is more conceptual because we can't directly verify
    //   // Finalizer.attach/detach without triggering GC and observing its effects.
    //   // We assume Finalizer works as expected.
    //
    //   var obj = TestObject('objToAttach');
    //   var token = FinalizationToken('tokenToAttach');
    //   var weakRef = WeakReference(obj);
    //
    //   // Attach should not throw
    //   expect(
    //       () =>
    //           queue.attach(weakRef, token, finalizationCallback: visitCallback),
    //       returnsNormally);
    //
    //   // Detach should not throw
    //   expect(() => queue.detach(weakRef), returnsNormally);
    //
    //   // Attaching with a null target should do nothing and not throw
    //   TestObject? nullTarget = TestObject('nullTarget');
    //   var nullTargetRef = WeakReference<TestObject>(
    //       nullTarget); // Create a WeakRef with null target
    //   nullTarget = null;
    //   await waiteGC(nullTarget as Object);
    //   expect(
    //       () => queue.attach(nullTargetRef, token,
    //           finalizationCallback: visitCallback),
    //       returnsNormally);
    //   // And expungeStale should still work
    //   queue.expungeStale(visitCallback);
    //   expect(finalizedTokens, isEmpty);
    // });
    //
    // test('expungeStale processes items added to the queue (simulated GC)', () {
    //   var obj1 = TestObject('obj1'); // Kept alive by this reference for now
    //   var token1 = FinalizationToken('data1');
    //   var finalizationCallback1Called = false;
    //   FinalizationToken? receivedToken1;
    //
    //   queue.attach(WeakReference(obj1), token1, finalizationCallback: (t) {
    //     finalizationCallback1Called = true;
    //     receivedToken1 = t;
    //   });
    //
    //   var obj2 = TestObject('obj2');
    //   var token2 = FinalizationToken('data2');
    //   var finalizationCallback2Called = false;
    //   FinalizationToken? receivedToken2;
    //
    //   queue.attach(WeakReference(obj2), token2, finalizationCallback: (t) {
    //     finalizationCallback2Called = true;
    //     receivedToken2 = t;
    //   });
    //
    //   var refToStaleWeakEntry = WeakReference(null as TestObject);
    //   queue.attach(refToStaleWeakEntry, token2);
    //
    //   // Entry 3 (similar to entry 1)
    //   var obj3 = TestObject('obj3');
    //   var token3 = FinalizationToken('data3');
    //   var finalizationCallback3Called = false;
    //   FinalizationToken? receivedToken3;
    //   queue.attach(WeakReference(obj3), token3, finalizationCallback: (t) {
    //     finalizationCallback3Called = true;
    //     receivedToken3 = t;
    //   });
    //
    //   expect(queue.isNotEmpty, isTrue);
    //
    //   queue.expungeStale(
    //       visitCallback); // visitCallback is the one passed to expungeStale
    //
    //   expect(queue.isEmpty, isTrue); // Queue should be empty after expunging
    //
    //   // Check that the original finalizationCallbacks within _FinalizationToken were called
    //   // AND that the visitCallback passed to expungeStale was called with the correct tokens.
    //   expect(finalizationCallback1Called, isTrue,
    //       reason: "Original callback for token1 not called");
    //   expect(receivedToken1, token1);
    //   // For token2, the _WeakEntry itself was "GC'd" (target of WeakReference in queue is null)
    //   // so its finalizer in _FinalizationToken would not be called by expungeStale's path
    //   // but if _finalize was called for it before its _WeakEntry target became null,
    //   // its finalizer would have been called there.
    //   // Here we only added WeakReference(we2) to the queue, and then a null one.
    //   // So ft2.finalizer will be called.
    //   expect(finalizationCallback2Called, isTrue,
    //       reason: "Original callback for token2 not called");
    //   expect(receivedToken2, token2);
    //
    //   expect(finalizationCallback3Called, isTrue,
    //       reason: "Original callback for token3 not called");
    //   expect(receivedToken3, token3);
    //
    //   // Check the tokens received by the `visit` callback of `expungeStale`
    //   expect(finalizedTokens, containsAllInOrder([token1, token2, token3]));
    // });
    //
    // test('expungeStale on an empty queue does nothing', () {
    //   expect(queue.isEmpty, isTrue);
    //   queue.expungeStale(visitCallback);
    //   expect(queue.isEmpty, isTrue);
    //   expect(finalizedTokens, isEmpty);
    // });

    // ... (之前的 TestObject, FinalizationToken, setUp, visitCallback 保持不变)

    test('expungeStale processes finalized items after GC', () async {
      TestObject? obj1 = TestObject('obj1_gc');
      var token1 = FinalizationToken('token1_gc');
      bool cb1Called = false;
      FinalizationToken? receivedToken1ByCb;

      TestObject? obj2 = TestObject('obj2_gc');
      var token2 = FinalizationToken('token2_gc');
      bool cb2Called = false;
      FinalizationToken? receivedToken2ByCb;

      queue.attach(WeakReference(obj1), token1, finalizationCallback: (t) {
        cb1Called = true;
        receivedToken1ByCb = t;
      });
      queue.attach(WeakReference(obj2), token2, finalizationCallback: (t) {
        cb2Called = true;
        receivedToken2ByCb = t;
      });
      // final refKeeper1 = obj1;
      // final refKeeper2 = obj2;

      // objects.add(token1);
      // objects.add(token2);

      afterGC(() {
        expect(cb1Called, isTrue,
            reason: "Original callback for token1 not called after GC sim");
        expect(receivedToken1ByCb, token1);
        expect(cb2Called, isTrue,
            reason: "Original callback for token2 not called after GC sim");
        expect(receivedToken2ByCb, token2);

        expect(cb1Called, isTrue,
            reason: "Original callback for token1 not called after GC sim");
        expect(receivedToken1ByCb, token1);
        expect(cb2Called, isTrue,
            reason: "Original callback for token2 not called after GC sim");
        expect(receivedToken2ByCb, token2);

        // Now, the internal queue should have entries
        expect(queue.isNotEmpty, isTrue,
            reason: "Queue should be non-empty after GC and finalization");

        queue.expungeStale(
            visitCallback); // visitCallback is the one passed to expungeStale

        expect(queue.isEmpty, isTrue,
            reason: "Queue should be empty after expunging");
        expect(finalizedTokens, unorderedEquals([token1, token2]));
        expect(finalizedTokens.length, 2);

        // Keep refs alive until after GC trigger for safety in test if not reassigning to null
        // print(refKeeper1.id);
        // print(refKeeper2.id);
      });

      obj1 = null;
      obj2 = null;
    });

    /// 写一个测试 当token 回收后 也不触犯添加到queue
    test('expungeStale processes finalized token after GC', () async {
      TestObject? obj1 = TestObject('obj1_gc');
      FinalizationToken? token1 = FinalizationToken('token1_gc');
      bool cb1Called = false;
      FinalizationToken? receivedToken1ByCb;
      queue.attach(WeakReference(obj1), token1, finalizationCallback: (t) {
        cb1Called = true;
        receivedToken1ByCb = t;
      });

      afterGC(() {
        expect(cb1Called, false);
        expect(receivedToken1ByCb, null);

        expect(queue, isEmpty);
        queue.expungeStale(visitCallback);

        expect(finalizedTokens, isEmpty);
      });
      obj1 = null;
      token1 = null;
    });

    test('clear makes the queue empty after GC and expunge ', () async {
      TestObject? objToClear = TestObject('objToClear');
      var tokenToClear = FinalizationToken('tokenToClear');
      bool cbClearCalled = false;

      queue.attach(WeakReference(objToClear), tokenToClear,
          finalizationCallback: (t) {
        cbClearCalled = true;
      });

      objects.add(tokenToClear);

      afterGC(() {
        expect(cbClearCalled, isTrue,
            reason: "Original callback for tokenToClear not called");
        expect(queue.isNotEmpty, isTrue,
            reason: "Queue should be non-empty before clear");

        queue.clear();
        expect(queue.isEmpty, isTrue,
            reason: "Queue should be empty immediately after clear");

        // Expunge again to see if anything lingering is processed (should not be)
        finalizedTokens.clear(); // Clear tokens from visitCallback
        queue.expungeStale(visitCallback);
        expect(finalizedTokens, isEmpty,
            reason:
                "No tokens should be processed by expungeStale after clear");
        expect(queue.isEmpty, isTrue);
      });
      objToClear = null;
    });

    test('detach makes the queue empty', () async {
      TestObject? obj1 = TestObject('obj1');
      var token1 = FinalizationToken('token1');
      var weakRef1 = WeakReference(obj1);
      bool cb1Called = false;
      FinalizationToken? receivedToken1ByCb;

      queue.attach(weakRef1, token1, finalizationCallback: (t) {
        cb1Called = true;
        receivedToken1ByCb = t;
      });

      queue.detach(weakRef1);

      expect(queue.isEmpty, isTrue);
      objects.add(token1);

      afterGC(() {
        expect(cb1Called, false);
        expect(receivedToken1ByCb, isNull);
        expect(queue.isEmpty, isTrue);
      });

      obj1 = null;
    });

    test('attach multiple times will only retain the effect once', () async {
      TestObject? obj1 = TestObject('obj1');
      var token1 = FinalizationToken('token1');
      var weakRef1 = WeakReference(obj1);
      int calledTimes = 0;

      queue.attach(weakRef1, token1, finalizationCallback: (t) {
        calledTimes++;
      });

      queue.attach(weakRef1, token1, finalizationCallback: (t) {
        calledTimes++;
      });

      objects.add(token1);
      afterGC(() {
        expect(calledTimes, 1);
        expect(queue.isNotEmpty, isTrue);
      });

      obj1 = null;
    });
  });
}
