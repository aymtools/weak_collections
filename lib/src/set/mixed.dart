part of 'hash_set.dart';



mixin MixedRefHashSetMixin<E extends Object> on WeakHashSetMixin<E> {
  @override
  void _removeEntry(_WeakHashSetEntry<E> entry,
      _WeakHashSetEntry<E>? previousInBucket, int bucketIndex) {

    if (previousInBucket == null) {
      _buckets[bucketIndex] = entry.remove();
    } else {
      previousInBucket.next = entry.remove();
    }
  }

  @override
  _WeakHashSetEntry<E> _makeEntry(
          E value,
          int hashCode,
          _WeakHashSetEntry<E>? next,
          WeakReferenceQueue<E, _WeakHashSetEntry<E>> queue) =>
      _WeakHashSetEntry<E>(value, hashCode, next, queue);
}
