import 'dart:collection';

// ignore: constant_identifier_names
const int _MODIFICATION_COUNT_MASK = 0x3fffffff;

class _WeakHashSetEntry<E extends Object> {
  final WeakReference<E> keyWeakRef;
  _WeakHashSetEntry<E>? next;

  final Finalizer<WeakReference<_WeakHashSetEntry<E>>> finalizer;

  @override
  final int hashCode;

  _WeakHashSetEntry(E key, this.hashCode, this.next, this.finalizer)
      : keyWeakRef = WeakReference(key) {
    finalizer.attach(key, WeakReference(this), detach: keyWeakRef);
  }

  _WeakHashSetEntry<E>? remove() {
    finalizer.detach(keyWeakRef);

    final result = next;
    next = null;
    return result;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other);
  }
}

class _WeakHashSetIterator<E extends Object> implements Iterator<E> {
  final WeakHashSet<E> _set;
  final int _modificationCount;
  int _index = 0;
  _WeakHashSetEntry<E>? _next;
  E? _current;

  _WeakHashSetIterator(this._set)
      : _modificationCount = _set._modificationCount;

  @override
  bool moveNext() {
    if (_modificationCount != _set._modificationCount) {
      throw ConcurrentModificationError(_set);
    }
    var localNext = _next;
    while (localNext != null) {
      var key = localNext.keyWeakRef.target;
      if (key != null) {
        _current = key;
        _next = localNext.next;
        return true;
      }
      localNext = localNext.next;
    }
    final buckets = _set._buckets;
    while (_index < buckets.length) {
      localNext = buckets[_index];
      _index = _index + 1;
      while (localNext != null) {
        var key = localNext.keyWeakRef.target;
        if (key != null) {
          _current = key;
          _next = localNext.next;
          return true;
        }
        localNext = localNext.next;
      }
    }
    _current = null;
    return false;
  }

  @override
  E get current => _current as E;
}

class WeakHashSet<E extends Object> with SetMixin<E> {
// ignore: constant_identifier_names
  static const int _INITIAL_CAPACITY = 8;

  var _buckets = List<_WeakHashSetEntry<E>?>.filled(_INITIAL_CAPACITY, null);
  int _elementCount = 0;
  int _modificationCount = 0;

  bool _equals(Object? e1, Object? e2) => e1 == e2;

  int _hashCode(Object? e) => e.hashCode;

  // static Set<R> _newEmpty<R extends Object>() => WeakSet<R>();

  final Queue<WeakReference<_WeakHashSetEntry<E>>> _queue = Queue();
  late final Finalizer<WeakReference<_WeakHashSetEntry<E>>> _finalizer =
      Finalizer((entry) {
    if (entry.target != null) {
      _queue.add(entry);
    }
  });

  // Iterable.
  @override
  Iterator<E> get iterator {
    _expungeStaleEntries();
    return _WeakHashSetIterator<E>(this);
  }

  @override
  int get length {
    _expungeStaleEntries();
    return _elementCount;
  }

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => length != 0;

  void _expungeStaleEntries() {
    if (_queue.isEmpty) return;
    _WeakHashSetEntry<E> e;
    while (_queue.isNotEmpty) {
      final entity = _queue.removeFirst().target;
      if (entity == null) continue;
      e = entity;
      int index = e.hashCode & (_buckets.length - 1);
      var entry = _buckets[index];
      if (entry == null) continue;
      if (entry == e) {
        _buckets[index] = e.next;
        _elementCount--;
      } else {
        _WeakHashSetEntry<E>? c;
        while ((c = entry?.next) != null) {
          if (_equals(c, e)) {
            entry?.next = e.remove();
            _elementCount--;
            break;
          }
          entry = c;
        }
      }
    }
    _modificationCount = (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
  }

  @override
  bool contains(Object? element) {
    if (element == null) return false;
    int index = _hashCode(element) & (_buckets.length - 1);
    var entry = _buckets[index];
    while (entry != null) {
      if (_equals(entry.keyWeakRef.target, element)) return true;
      entry = entry.next;
    }
    return false;
  }

  @override
  E? lookup(Object? element) {
    if (element == null) return null;
    int index = _hashCode(element) & (_buckets.length - 1);
    var entry = _buckets[index];
    while (entry != null) {
      var key = entry.keyWeakRef.target;
      if (_equals(key, element)) return key;
      entry = entry.next;
    }
    return null;
  }

  @override
  E get first {
    for (int i = 0; i < _buckets.length; i++) {
      var entry = _buckets[i];
      while (entry != null) {
        var key = entry.keyWeakRef.target;
        if (key != null) return key;
        entry = entry.next;
      }
    }
    throw StateError("No element");
  }

  @override
  E get last {
    E? e;
    for (int i = _buckets.length - 1; i >= 0; i--) {
      var entry = _buckets[i];
      while (entry != null) {
        if (entry.keyWeakRef.target != null) {
          e = entry.keyWeakRef.target;
        }
        entry = entry.next;
      }
      if (e != null) return e;
    }

    throw StateError("No element");
  }

  bool _add(E value) {
    final hashCode = _hashCode(value);
    final index = hashCode & (_buckets.length - 1);
    var entry = _buckets[index];
    while (entry != null) {
      if (_equals(entry.keyWeakRef.target, value)) return false;
      entry = entry.next;
    }
    _addEntry(value, hashCode, index);
    return true;
  }

  @override
  bool add(E value) {
    _expungeStaleEntries();
    return _add(value);
  }

  @override
  void addAll(Iterable<E> elements) {
    _expungeStaleEntries();
    for (E object in elements) {
      _add(object);
    }
  }

  bool _remove(Object? object, int hashCode) {
    final index = hashCode & (_buckets.length - 1);
    var entry = _buckets[index];
    _WeakHashSetEntry<E>? previous;
    while (entry != null) {
      if (_equals(entry.keyWeakRef.target, object)) {
        final next = entry.remove();
        if (previous == null) {
          _buckets[index] = next;
        } else {
          previous.next = next;
        }
        _elementCount--;
        _modificationCount =
            (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
        return true;
      }
      previous = entry;
      entry = entry.next;
    }
    return false;
  }

  @override
  bool remove(Object? value) {
    _expungeStaleEntries();
    if (value == null) return false;

    return _remove(value, _hashCode(value));
  }

  @override
  void removeAll(Iterable<Object?> elements) {
    _expungeStaleEntries();
    for (Object? object in elements) {
      if (object == null) continue;
      _remove(object, _hashCode(object));
    }
  }

  void _filterWhere(bool Function(E element) test, bool removeMatching) {
    int length = _buckets.length;
    for (int index = 0; index < length; index++) {
      var entry = _buckets[index];
      _WeakHashSetEntry<E>? previous;
      while (entry != null) {
        int modificationCount = _modificationCount;
        E? target = entry.keyWeakRef.target;
        if (target == null) {
          previous = entry;
          entry = entry.next;
          continue;
        }
        bool testResult = test(target);
        if (modificationCount != _modificationCount) {
          throw ConcurrentModificationError(this);
        }
        if (testResult == removeMatching) {
          final next = entry.remove();
          if (previous == null) {
            _buckets[index] = next;
          } else {
            previous.next = next;
          }
          _elementCount--;
          _modificationCount =
              (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
          entry = next;
        } else {
          previous = entry;
          entry = entry.next;
        }
      }
    }
  }

  @override
  void removeWhere(bool Function(E element) test) {
    _expungeStaleEntries();
    _filterWhere(test, true);
  }

  @override
  void retainWhere(bool Function(E element) test) {
    _expungeStaleEntries();
    _filterWhere(test, false);
  }

  @override
  void clear() {
    _queue.clear();
    _buckets = List<_WeakHashSetEntry<E>?>.filled(_INITIAL_CAPACITY, null);
    if (_elementCount > 0) {
      _elementCount = 0;
      _modificationCount = (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
    }
  }

  void _addEntry(E key, int hashCode, int index) {
    _buckets[index] =
        _WeakHashSetEntry<E>(key, hashCode, _buckets[index], _finalizer);
    int newElements = _elementCount + 1;
    _elementCount = newElements;
    int length = _buckets.length;
    // If we end up with more than 75% non-empty entries, we
    // resize the backing store.
    if ((newElements << 2) > ((length << 1) + length)) _resize();
    _modificationCount = (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
  }

  void _resize() {
    final oldLength = _buckets.length;
    final newLength = oldLength << 1;
    final oldBuckets = _buckets;
    final newBuckets = List<_WeakHashSetEntry<E>?>.filled(newLength, null);
    for (int i = 0; i < oldLength; i++) {
      var entry = oldBuckets[i];
      while (entry != null) {
        final next = entry.next;
        int newIndex = entry.hashCode & (newLength - 1);
        entry.next = newBuckets[newIndex];
        newBuckets[newIndex] = entry;
        entry = next;
      }
    }
    _buckets = newBuckets;
  }

  //会生成强引用
  @override
  Set<E> toSet() {
    _expungeStaleEntries();
    Set<E> result = {};
    for (int i = 0; i < _buckets.length; i++) {
      var entry = _buckets[i];
      while (entry != null) {
        var temp = entry.keyWeakRef.target;
        if (temp != null) {
          result.add(temp);
        }
        entry = entry.next;
      }
    }
    return result;
  }
}
