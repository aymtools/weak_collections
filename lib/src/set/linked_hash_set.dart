part of 'hash_set.dart';

class _WeakLinkedHashSetEntry<E extends Object> extends _WeakHashSetEntry<E> {
  WeakLinkedNode<_WeakLinkedHashSetEntry<E>>? node;

  _WeakLinkedHashSetEntry(super.key, super.hashCode, super.next, super.queue) {
    node = WeakLinkedNode(this);
  }

  @override
  _WeakHashSetEntry<E>? remove() {
    node = null;
    return super.remove();
  }
}

class _WeakLinkedHashSetIterator<E extends Object> implements Iterator<E> {
  final WeakLinkedHashSet<E> _set;
  final int _modificationCount;
  WeakLinkedNode<_WeakHashSetEntry<E>>? _next;
  E? _current;

  _WeakLinkedHashSetIterator(this._set)
      : _modificationCount = _set._modificationCount,
        _next = _set._head;

  @override
  E get current => _current as E;

  @override
  bool moveNext() {
    if (_modificationCount != _set._modificationCount) {
      throw ConcurrentModificationError(_set);
    }
    _current = null;
    var localNext = _next;
    while (localNext != null) {
      var key = localNext.value.value;
      if (key != null) {
        _current = key;
        _next = localNext.next;
        return true;
      }
      localNext = localNext.next;
    }
    return false;
  }
}

class WeakLinkedHashSet<E extends Object> extends WeakHashSet<E>
    implements LinkedHashSet<E> {
  WeakLinkedNode<_WeakLinkedHashSetEntry<E>>? _head;
  WeakLinkedNode<_WeakLinkedHashSetEntry<E>>? _tail;

  WeakLinkedHashSet();

  factory WeakLinkedHashSet.identity() => _IdentityWeakLinkedHashSet<E>();

  factory WeakLinkedHashSet.from(Iterable<dynamic> elements) {
    WeakLinkedHashSet<E> result = WeakLinkedHashSet<E>();
    for (final element in elements) {
      result.add(element as E);
    }
    return result;
  }

  factory WeakLinkedHashSet.of(Iterable<E> elements) =>
      WeakLinkedHashSet<E>()..addAll(elements);

  factory WeakLinkedHashSet.custom(
      {bool Function(E, E)? equals,
      int Function(E)? hashCode,
      bool Function(Object?)? isValidKey}) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return WeakLinkedHashSet<E>();
        }
        hashCode = defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return _IdentityWeakLinkedHashSet<E>();
        }
        equals ??= defaultEquals;
      }
    } else {
      hashCode ??= defaultHashCode;
      equals ??= defaultEquals;
    }
    return _CustomWeakLinkedHashSet<E>(equals, hashCode, isValidKey);
  }

  @override
  Iterator<E> get iterator => _WeakLinkedHashSetIterator<E>(this);

  @override
  E get first {
    var node = _head;
    if (node != null) {
      E? target = node.value.value;
      if (target != null) {
        return target;
      }
      node = node.next;
    }

    throw StateError("No element");
  }

  @override
  E get last {
    var node = _tail;
    if (node != null) {
      E? target = node.value.value;
      if (target != null) {
        return target;
      }
      node = node.prev;
    }
    throw StateError("No element");
  }

  @override
  _WeakHashSetEntry<E> _makeEntry(
      E value,
      int hashCode,
      _WeakHashSetEntry<E>? next,
      WeakReferenceQueue<E, _WeakHashSetEntry<E>> queue) {
    final entry = _WeakLinkedHashSetEntry<E>(value, hashCode, next, queue);
    final node = entry.node!;
    if (_head == null) {
      _head = node;
      _tail = node;
    } else {
      final tail = _tail!;
      tail.next = node;
      node.prev = tail;
      _tail = node;
    }
    return entry;
  }

  @override
  void _removeEntry(_WeakHashSetEntry<E> entry,
      _WeakHashSetEntry<E>? previousInBucket, int bucketIndex) {
    final node = (entry as _WeakLinkedHashSetEntry<E>).node;
    if (node != null) {
      final prev = node.prev;
      final next = node.next;

      // 1. 处理前驱方向：如果是头节点更新 _head，否则链接前驱和后继
      if (prev == null) {
        _head = next;
      } else {
        prev.next = next;
      }

      // 2. 处理后继方向：如果是尾节点更新 _tail，否则链接后继和前驱
      if (next == null) {
        _tail = prev;
      } else {
        next.prev = prev;
      }

      // 3. 清理当前节点的引用，防止内存泄漏
      node.next = null;
      node.prev = null;
    }
    super._removeEntry(entry, previousInBucket, bucketIndex);
  }

  @override
  void _expungeStaleEntries() {
    if (_head == null) return;
    super._expungeStaleEntries();
  }

  @override
  void clear() {
    super.clear();
    _head = null;
    _tail = null;
  }

  @override
  Set<E> _newSet() => WeakLinkedHashSet<E>();

  @override
  Set<E> toSet() {
    final set = super.toSet();
    if (set is WeakLinkedHashSet<E>) {
      set._head = _head;
      set._tail = _tail;
    }
    return set;
  }
}

class _IdentityWeakLinkedHashSet<E extends Object> extends WeakLinkedHashSet<E>
    with _IdentityWeakHashSetMixin<E> {
  @override
  WeakHashSet<E> _newSet() => _IdentityWeakLinkedHashSet<E>();
}

class _CustomWeakLinkedHashSet<E extends Object> extends WeakLinkedHashSet<E>
    with _CustomWeakHashSetMixin<E> {
  @override
  final bool Function(E, E) _equality;
  @override
  final int Function(E) _hasher;
  @override
  final bool Function(Object?) _validKey;

  _CustomWeakLinkedHashSet(
      this._equality, this._hasher, bool Function(Object?)? validKey)
      : _validKey = (validKey != null) ? validKey : TypeTest<E>().test;

  @override
  WeakHashSet<E> _newSet() =>
      _CustomWeakLinkedHashSet<E>(_equality, _hasher, _validKey);
}

@visibleForTesting
extension WeakLinkedHashSetTestExt<E extends Object> on WeakLinkedHashSet<E> {
  @visibleForTesting
  bool get headEqNull => _head == null;

  @visibleForTesting
  bool get tailEqNull => _tail == null;

  @visibleForTesting
  bool get headEqTail => _head == _tail;

  @visibleForTesting
  E? get headValue => _head?.value.value;

  @visibleForTesting
  E? get tailValue => _tail?.value.value;
}
