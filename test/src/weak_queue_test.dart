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
}
