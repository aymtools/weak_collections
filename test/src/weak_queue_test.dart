import 'dart:collection';
import 'package:test/test.dart';
import 'package:weak_collections/src/weak_queue.dart';

import '../tools.dart';

void main() {
  group('WeakQueue', () {
    test('.contains()', () {
      final set = WeakQueue<TestVal>();

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
      final queue = WeakQueue<TestVal>();

      final v1 = TestVal('a');
      final v2 = TestVal('b');
      final v3 = TestVal('c');

      queue.addAll([v1, v2, v3]);

      queue.remove(v2);

      expect(queue.length, equals(2));
      expect(queue.contains(v2), isFalse);
    });

    test('.addFirst()', () {
      final queue = WeakQueue<TestVal>();
      final v1 = TestVal('a');
      final v2 = TestVal('b');
      final v3 = TestVal('c');

      queue.addAll([v1, v2, v3]);

      final target = TestVal('d');
      queue.addFirst(target);

      expect(queue.length, equals(4));
      expect(queue.first == target, isTrue);
    });

    test('.addLast()', () {
      final queue = WeakQueue<TestVal>();
      final v1 = TestVal('a');
      final v2 = TestVal('b');
      final v3 = TestVal('c');

      queue.addAll([v1, v2, v3]);

      final target = TestVal('d');
      queue.addLast(target);

      expect(queue.length, equals(4));
      expect(queue.last == target, isTrue);
    });

    test('.removeFirst()', () {
      final queue = WeakQueue<TestVal>();
      final v1 = TestVal('a');
      final v2 = TestVal('b');
      final v3 = TestVal('c');

      queue.addAll([v1, v2, v3]);

      final r = queue.removeFirst();

      expect(queue.length, equals(2));
      expect(v1 == r, isTrue);
    });

    test('.removeLast()', () {
      final queue = WeakQueue<TestVal>();
      final v1 = TestVal('a');
      final v2 = TestVal('b');
      final v3 = TestVal('c');

      queue.addAll([v1, v2, v3]);

      final r = queue.removeLast();

      expect(queue.length, equals(2));
      expect(v3 == r, isTrue);
    });
  });

  group('WeakQueue()', () {
    test('creates an empty WeakQueue', () {
      expect(WeakQueue(), isEmpty);
    });

    test('creates an WeakQueue add NotEmpty', () {
      final queue = WeakQueue<TestVal>();
      queue.add(TestVal('a'));
      expect(queue, isNotEmpty);
    });
  });

  group('add()', () {
    test('adds an element to the end of the queue', () {
      final queue = WeakQueue<TestVal>();
      final a = TestVal('a');
      final b = TestVal('b');
      final c = TestVal('c');

      queue.add(a);
      queue.add(b);
      queue.add(c);
      expect(queue, equals([a, b, c]));
    });

    // test('expands a full queue', () {
    //   var queue = atCapacity();
    //   queue.add(8);
    //   expect(queue, equals([1, 2, 3, 4, 5, 6, 7, 8]));
    // });
  });

  group('addAll()', () {
    test('adds elements to the end of the queue', () {
      final queue = WeakQueue<TestVal>();
      final a = TestVal('a');
      queue.add(a);
      final b = TestVal('b');
      final c = TestVal('c');
      final d = TestVal('d');
      queue.addAll([b, c, d]);
      expect(queue, equals([a, b, c, d]));
    });

    // test('expands a full queue', () {
    //   var queue = atCapacity();
    //   queue.addAll([8, 9]);
    //   expect(queue, equals([1, 2, 3, 4, 5, 6, 7, 8, 9]));
    // });
  });

  group('addFirst()', () {
    test('adds an element to the beginning of the queue', () {
      final queue = WeakQueue<TestVal>();
      final a = TestVal('a');
      final b = TestVal('b');
      queue.add(a);
      queue.add(b);

      final c = TestVal('c');
      queue.addFirst(c);
      expect(queue, equals([c, a, b]));
    });

    // test('expands a full queue', () {
    //   var queue = atCapacity();
    //   queue.addFirst(0);
    //   expect(queue, equals([0, 1, 2, 3, 4, 5, 6, 7]));
    // });
  });

  group('removeFirst()', () {
    test('removes an element from the beginning of the queue', () {
      final queue = WeakQueue<TestVal>();
      final a = TestVal('a');
      final b = TestVal('b');
      final c = TestVal('c');
      queue.addAll([a, b, c]);
      expect(queue.removeFirst(), equals(a));
      expect(queue, equals([b, c]));
    });

    // test(
    //     'removes an element from the beginning of a queue with an internal '
    //     'gap', () {
    //   var queue = withInternalGap();
    //   expect(queue.removeFirst(), equals(1));
    //   expect(queue, equals([2, 3, 4, 5, 6, 7]));
    // });
    //
    // test('removes an element from the beginning of a queue at capacity', () {
    //   var queue = atCapacity();
    //   expect(queue.removeFirst(), equals(1));
    //   expect(queue, equals([2, 3, 4, 5, 6, 7]));
    // });

    test('throws a StateError for an empty queue', () {
      expect(WeakQueue().removeFirst, throwsStateError);
    });
  });

  group('removeLast()', () {
    test('removes an element from the end of the queue', () {
      final queue = WeakQueue<TestVal>();
      final a = TestVal('a');
      final b = TestVal('b');
      final c = TestVal('c');
      queue.addAll([a, b, c]);
      expect(queue.removeLast(), equals(c));
      expect(queue, equals([a, b]));
    });

    // test('removes an element from the end of a queue with an internal gap', () {
    //   var queue = withInternalGap();
    //   expect(queue.removeLast(), equals(7));
    //   expect(queue, equals([1, 2, 3, 4, 5, 6]));
    // });
    //
    // test('removes an element from the end of a queue at capacity', () {
    //   var queue = atCapacity();
    //   expect(queue.removeLast(), equals(7));
    //   expect(queue, equals([1, 2, 3, 4, 5, 6]));
    // });

    test('throws a StateError for an empty queue', () {
      expect(WeakQueue().removeLast, throwsStateError);
    });
  });

  group('length', () {
    test('returns the length of a queue', () {
      final queue = WeakQueue<TestVal>();
      final a = TestVal('a');
      final b = TestVal('b');
      final c = TestVal('c');
      queue.addAll([a, b, c]);
      expect(queue.length, equals(3));
    });

    // test('returns the length of a queue with an internal gap', () {
    //   expect(withInternalGap().length, equals(7));
    // });
    //
    // test('returns the length of a queue at capacity', () {
    //   expect(atCapacity().length, equals(7));
    // });
  });

  // group('length=', () {
  //   test('shrinks a larger queue', () {
  //     final queue = WeakQueue<TestVal>();
  //     final a = TestVal('a');
  //     final b = TestVal('b');
  //     final c = TestVal('c');
  //     queue.addAll([a, b, c]);
  //
  //     queue.length = 1;
  //     expect(queue, equals([a]));
  //   });
  //
  //   test('grows a smaller queue', () {
  //     var queue = QueueList<int?>.from([1, 2, 3]);
  //     queue.length = 5;
  //     expect(queue, equals([1, 2, 3, null, null]));
  //   });
  //
  //   test('throws a RangeError if length is less than 0', () {
  //     expect(() => QueueList().length = -1, throwsRangeError);
  //   });
  //
  //   test('throws an UnsupportedError if element type is non-nullable', () {
  //     expect(() => QueueList<int>().length = 1, throwsUnsupportedError);
  //   });
  // });

  // group('[]', () {
  //   test('returns individual entries in the queue', () {
  //     final queue = WeakQueue<TestVal>();
  //     final a = TestVal('a');
  //     final b = TestVal('b');
  //     final c = TestVal('c');
  //     queue.addAll([a, b, c]);
  //
  //     expect(queue[0], equals(1));
  //     expect(queue[1], equals(2));
  //     expect(queue[2], equals(3));
  //   });
  //
  //   test('returns individual entries in a queue with an internal gap', () {
  //     var queue = withInternalGap();
  //     expect(queue[0], equals(1));
  //     expect(queue[1], equals(2));
  //     expect(queue[2], equals(3));
  //     expect(queue[3], equals(4));
  //     expect(queue[4], equals(5));
  //     expect(queue[5], equals(6));
  //     expect(queue[6], equals(7));
  //   });
  //
  //   test('throws a RangeError if the index is less than 0', () {
  //     final queue = WeakQueue<TestVal>();
  //     final a = TestVal('a');
  //     final b = TestVal('b');
  //     final c = TestVal('c');
  //     queue.addAll([a, b, c]);
  //     expect(() => queue[-1], throwsRangeError);
  //   });
  //
  //   test(
  //       'throws a RangeError if the index is greater than or equal to the '
  //       'length', () {
  //     final queue = WeakQueue<TestVal>();
  //     final a = TestVal('a');
  //     final b = TestVal('b');
  //     final c = TestVal('c');
  //     queue.addAll([a, b, c]);
  //     expect(() => queue[3], throwsRangeError);
  //   });
  // });
  //
  // group('[]=', () {
  //   test('sets individual entries in the queue', () {
  //     final queue = WeakQueue<TestVal>();
  //     final a = TestVal('a');
  //     final b = TestVal('b');
  //     final c = TestVal('c');
  //     queue.addAll([a, b, c]);
  //     queue[0] = 'a';
  //     queue[1] = 'b';
  //     queue[2] = 'c';
  //     expect(queue, equals(['a', 'b', 'c']));
  //   });
  //
  //   test('sets individual entries in a queue with an internal gap', () {
  //     var queue = withInternalGap();
  //     queue[0] = 'a';
  //     queue[1] = 'b';
  //     queue[2] = 'c';
  //     queue[3] = 'd';
  //     queue[4] = 'e';
  //     queue[5] = 'f';
  //     queue[6] = 'g';
  //     expect(queue, equals(['a', 'b', 'c', 'd', 'e', 'f', 'g']));
  //   });
  //
  //   test('throws a RangeError if the index is less than 0', () {
  //     var queue = QueueList.from([1, 2, 3]);
  //     expect(() {
  //       queue[-1] = 0;
  //     }, throwsRangeError);
  //   });
  //
  //   test(
  //       'throws a RangeError if the index is greater than or equal to the '
  //       'length', () {
  //     var queue = QueueList.from([1, 2, 3]);
  //     expect(() {
  //       queue[3] = 4;
  //     }, throwsRangeError);
  //   });
  // });

  group('throws a modification error for', () {
    dynamic queue;
    setUp(() {
      queue = WeakQueue<TestVal>();
      final a = TestVal('a');
      final b = TestVal('b');
      final c = TestVal('c');
      queue.addAll([a, b, c]);
    });

    test('add', () {
      expect(
            () => queue.forEach((_) => queue.add(TestVal('d'))),
        throwsConcurrentModificationError,
      );
    });

    test('addAll', () {
      expect(
            () =>
            queue.forEach((_) =>
                queue.addAll([TestVal('d'), TestVal('e'), TestVal('f')])),
        throwsConcurrentModificationError,
      );
    });

    test('addFirst', () {
      expect(
            () => queue.forEach((_) => queue.addFirst(TestVal('z'))),
        throwsConcurrentModificationError,
      );
    });

    test('removeFirst', () {
      expect(
            () => queue.forEach((_) => queue.removeFirst()),
        throwsConcurrentModificationError,
      );
    });

    test('removeLast', () {
      expect(
            () => queue.forEach((_) => queue.removeLast()),
        throwsConcurrentModificationError,
      );
    });

    // test('length=', () {
    //   expect(
    //     () => queue.forEach((_) => queue.length = 1),
    //     throwsConcurrentModificationError,
    //   );
    // });
  });

  test('cast does not throw on mutation when the type is valid', () {
    final a = SubVal('a');
    final b = SubVal('b');
    final c = SubVal('c');
    final d = SubVal('d');

    var subValQueue = WeakQueue<TestVal>()
      ..addAll([a, b]);
    var testValQueue = subValQueue.cast<SubVal>();
    testValQueue.addAll([c, d]);
    expect(
      testValQueue,
      const TypeMatcher<Queue<SubVal>>(),
      reason: 'Expected WeakQueue<SubVal>, got ${testValQueue.runtimeType}',
    );

    expect(testValQueue, [a, b, c, d]);

    expect(subValQueue, testValQueue, reason: 'Should forward to original');
  });

  test('cast throws on mutation when the type is not valid', () {
    WeakQueue<Object> t1Queue = WeakQueue<TestVal>();
    var t2Queue = t1Queue.cast<Test2Val>();
    expect(
      t2Queue,
      const TypeMatcher<Queue<Test2Val>>(),
      reason: 'Expected Queue<Test2Val>, got ${t2Queue.runtimeType}',
    );
    expect(() => t2Queue.add(Test2Val('a')), throwsA(isA<TypeError>()));
  });

  test('cast returns a new QueueList', () {
    var queue = WeakQueue<SubVal>();
    expect(queue.cast<TestVal>(), isNot(same(queue)));
  });
}
//
// /// Returns a queue whose internal ring buffer is full enough that adding a new
// /// element will expand it.
// WeakQueue<TestVal> atCapacity() {
//   // Use addAll because `QueueList.from(list)` won't use the default initial
//   // capacity of 8.
//   final queue = WeakQueue<TestVal>();
//   queue.addAll([TestVal('1'), TestVal('2'), TestVal('3'), TestVal('4'), TestVal('5'), TestVal('6'), TestVal('7')]);
//   // The next add will expand the queue.
//   return queue;
// }
//
// /// Returns a queue whose internal tail has a lower index than its head.
// WeakQueue<TestVal> withInternalGap() {
//   final queue = WeakQueue<TestVal>();
//   queue.addAll(
//       [TestVal(''), TestVal(''), TestVal(''), TestVal(''), TestVal('1'), TestVal('2'), TestVal('3'), TestVal('4')]);
//   for (var i = 0; i < 4; i++) {
//     queue.removeFirst();
//   }
//   for (var i = 5; i < 8; i++) {
//     queue.addLast(TestVal('$i'));
//   }
//   return queue;
// }

/// Returns a matcher that expects that a closure throws a
/// [ConcurrentModificationError].
final throwsConcurrentModificationError = throwsA(
  const TypeMatcher<ConcurrentModificationError>(),
);

