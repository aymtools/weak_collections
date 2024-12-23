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
}
