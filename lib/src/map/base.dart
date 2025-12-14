part of 'hash_map.dart';

// ignore: constant_identifier_names
const int _MODIFICATION_COUNT_MASK = 0x3fffffff;

class _WeakHashMapEntry<K extends Object, V> {
  final WeakReference<K> keyWeakRef;
  V? value;

  K? get key => keyWeakRef.target;

  _WeakHashMapEntry<K, V>? next;

  // final Finalizer<WeakReference<_WeakHashMapEntry<K, V>>> finalizer;

  WeakReferenceQueue<K, _WeakHashMapEntry<K, V>>? _queue;

  @override
  final int hashCode;

  _WeakHashMapEntry(
    K key,
    this.value,
    this.hashCode,
    this.next,
    this._queue,
  ) : keyWeakRef = WeakReference(key) {
    _queue?.attach(keyWeakRef, this,
        finalizationCallback: _WeakHashMapEntry._finalize);
  }

  _WeakHashMapEntry<K, V>? remove() {
    _queue?.detach(keyWeakRef);
    _queue = null;
    value = null;

    final result = next;
    next = null;
    return result;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other);
  }

  static void _finalize(_WeakHashMapEntry entry) {
    entry.value = null;
    entry._queue = null;
  }
}

mixin WeakHashMapMixin<K extends Object, V> on MapMixin<K, V> {
  // ignore: constant_identifier_names
  static const int _INITIAL_CAPACITY = 8;

  final WeakReferenceQueue<K, _WeakHashMapEntry<K, V>> _queue =
      WeakReferenceQueue();

  int _elementCount = 0;
  var _buckets = List<_WeakHashMapEntry<K, V>?>.filled(_INITIAL_CAPACITY, null);
  int _modificationCount = 0;

  @override
  int get length {
    _expungeStaleEntries();
    return _elementCount;
  }

  @override
  bool get isEmpty => length == 0;

  @override
  bool get isNotEmpty => length != 0;

  @override
  Iterable<MapEntry<K, V>> get entries {
    _expungeStaleEntries();
    return super.entries;
  }

  void _expungeStaleEntries() {
    if (_queue.isEmpty) return;

    final count = _elementCount;
    _queue.expungeStale((e) {
      int index = e.hashCode & (_buckets.length - 1);
      var currentEntry = _buckets[index];
      _WeakHashMapEntry<K, V>? previousEntry;

      while (currentEntry != null) {
        if (identical(currentEntry, e)) {
          // _removeEntry 会处理 previousEntry 为 null (头节点) 或非 null (中间节点) 的情况
          _removeEntry(e, previousEntry, index);
          _elementCount--;
          break;
        }
        previousEntry = currentEntry;
        currentEntry = currentEntry.next;
      }
    });
    if (_elementCount != count) {
      _modificationCount = (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
    }
  }

  @override
  bool containsKey(Object? key) {
    if (key == null) return false;
    final hashCode = key.hashCode;
    final buckets = _buckets;
    final index = hashCode & (buckets.length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && entry.keyWeakRef.target == key) {
        return true;
      }
      entry = entry.next;
    }
    return false;
  }

  @override
  bool containsValue(Object? value) {
    final buckets = _buckets;
    final length = buckets.length;
    for (int i = 0; i < length; i++) {
      var entry = buckets[i];
      while (entry != null) {
        if (entry.keyWeakRef.target != null && entry.value == value) {
          return true;
        }
        entry = entry.next;
      }
    }
    return false;
  }

  void _put(K key, V value) {
    final hashCode = key.hashCode;
    final buckets = _buckets;
    final length = buckets.length;
    final index = hashCode & (length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && entry.keyWeakRef.target == key) {
        entry.value = value;
        return;
      }
      entry = entry.next;
    }
    _addEntry(buckets, index, length, key, value, hashCode);
  }

  @override
  V? operator [](Object? key) {
    if (key == null) return null;
    _expungeStaleEntries();
    final hashCode = key.hashCode;
    final buckets = _buckets;
    final index = hashCode & (buckets.length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && entry.keyWeakRef.target == key) {
        return entry.value;
      }
      entry = entry.next;
    }
    return null;
  }

  @override
  void operator []=(K key, V? value) {
    _expungeStaleEntries();
    if (value == null) {
      _remove(key);
      return;
    }
    _put(key, value);
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    _expungeStaleEntries();
    final hashCode = key.hashCode;
    final buckets = _buckets;
    final length = buckets.length;
    final index = hashCode & (length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && entry.keyWeakRef.target == key) {
        return entry.value!;
      }
      entry = entry.next;
    }
    final stamp = _modificationCount;
    final V value = ifAbsent();
    if (stamp == _modificationCount) {
      _addEntry(buckets, index, length, key, value, hashCode);
    } else {
      this[key] = value;
    }
    return value;
  }

  @override
  void addAll(Map<K, V> other) {
    _expungeStaleEntries();
    other.forEach(_put);
  }

  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    _expungeStaleEntries();
    for (var e in newEntries) {
      _put(e.key, e.value);
    }
  }

  @override
  void forEach(void Function(K key, V value) action) {
    _expungeStaleEntries();
    final stamp = _modificationCount;
    final buckets = _buckets;
    final length = buckets.length;
    for (int i = 0; i < length; i++) {
      var entry = buckets[i];
      while (entry != null) {
        K? k = entry.keyWeakRef.target;
        if (k == null) {
          entry = entry.next;
          continue;
        }
        action(k, entry.value as V);
        if (stamp != _modificationCount) {
          throw ConcurrentModificationError(this);
        }
        entry = entry.next;
      }
    }
  }

  V? _remove(Object? key) {
    if (key == null) return null;
    final hashCode = key.hashCode;
    final buckets = _buckets;
    final index = hashCode & (buckets.length - 1);
    var entry = buckets[index];
    _WeakHashMapEntry<K, V>? previous;
    while (entry != null) {
      final next = entry.next;
      if (hashCode == entry.hashCode && entry.keyWeakRef.target == key) {
        final value = entry.value;
        _removeEntry(entry, previous, index);
        _elementCount--;
        _modificationCount =
            (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
        return value;
      }
      previous = entry;
      entry = next;
    }
    return null;
  }

  @override
  V? remove(Object? key) {
    _expungeStaleEntries();
    return _remove(key);
  }

  @override
  void removeWhere(bool Function(K key, V value) test) {
    _expungeStaleEntries();
    var keysToRemove = <K>[];
    for (var key in keys) {
      if (test(key, this[key] as V)) keysToRemove.add(key);
    }
    for (var key in keysToRemove) {
      _remove(key);
    }
  }

  @override
  void clear() {
    _queue.clear();
    _buckets = List.filled(_INITIAL_CAPACITY, null);
    if (_elementCount > 0) {
      _elementCount = 0;
      _modificationCount = (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
    }
  }

  void _removeEntry(_WeakHashMapEntry<K, V> entry,
      _WeakHashMapEntry<K, V>? previousInBucket, int bucketIndex) {
    if (previousInBucket == null) {
      _buckets[bucketIndex] = entry.remove();
    } else {
      previousInBucket.next = entry.remove();
    }
  }

  _WeakHashMapEntry<K, V> _makeEntry(
          K key,
          V value,
          int hashCode,
          _WeakHashMapEntry<K, V>? next,
          WeakReferenceQueue<K, _WeakHashMapEntry<K, V>>? queue) =>
      _WeakHashMapEntry<K, V>(key, value, hashCode, next, queue);

  void _addEntry(List<_WeakHashMapEntry<K, V>?> buckets, int index, int length,
      K key, V value, int hashCode) {
    final entry = _makeEntry(key, value, hashCode, buckets[index], _queue);
    buckets[index] = entry;
    final newElements = _elementCount + 1;
    _elementCount = newElements;
    // If we end up with more than 75% non-empty entries, we
    // resize the backing store.
    if ((newElements << 2) > ((length << 1) + length)) _resize();
    _modificationCount = (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
  }

  void _resize() {
    final oldBuckets = _buckets;
    final oldLength = oldBuckets.length;
    final newLength = oldLength << 1;
    final newBuckets = List<_WeakHashMapEntry<K, V>?>.filled(newLength, null);
    for (int i = 0; i < oldLength; i++) {
      var entry = oldBuckets[i];
      while (entry != null) {
        final next = entry.next;
        final hashCode = entry.hashCode;
        final index = hashCode & (newLength - 1);
        entry.next = newBuckets[index];
        newBuckets[index] = entry;
        entry = next;
      }
    }
    _buckets = newBuckets;
  }

  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    _expungeStaleEntries();
    final hashCode = key.hashCode;
    final buckets = _buckets;
    final length = buckets.length;
    final index = hashCode & (length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && entry.keyWeakRef.target == key) {
        return entry.value = update(entry.value as V);
      }
      entry = entry.next;
    }
    if (ifAbsent != null) {
      V newValue = ifAbsent();
      _addEntry(buckets, index, length, key, newValue, hashCode);
      return newValue;
    } else {
      throw ArgumentError.value(key, "key", "Key not in map.");
    }
  }

  @override
  void updateAll(V Function(K key, V value) update) {
    _expungeStaleEntries();
    final stamp = _modificationCount;
    final buckets = _buckets;
    final length = buckets.length;
    for (int i = 0; i < length; i++) {
      var entry = buckets[i];
      while (entry != null) {
        K? k = entry.keyWeakRef.target;
        if (k == null) {
          entry = entry.next;
          continue;
        }
        entry.value = update(k, entry.value as V);
        if (stamp != _modificationCount) {
          throw ConcurrentModificationError(this);
        }
        entry = entry.next;
      }
    }
  }

  Set<K> _newKeySet() {
    Set<K> set = WeakHashSet<K>();
    return set;
  }
}

mixin _IdentityWeakHashMapMixin<K extends Object, V> on WeakHashMapMixin<K, V> {
  @override
  bool containsKey(Object? key) {
    final hashCode = identityHashCode(key);
    final buckets = _buckets;
    final index = hashCode & (buckets.length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode &&
          identical(entry.keyWeakRef.target, key)) {
        return true;
      }
      entry = entry.next;
    }
    return false;
  }

  @override
  V? operator [](Object? key) {
    if (key == null) return null;
    _expungeStaleEntries();
    final hashCode = identityHashCode(key);
    final buckets = _buckets;
    final index = hashCode & (buckets.length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode &&
          identical(entry.keyWeakRef.target, key)) {
        return entry.value;
      }
      entry = entry.next;
    }
    return null;
  }

  @override
  void operator []=(K key, V? value) {
    _expungeStaleEntries();
    if (value == null) {
      _remove(key);
      return;
    }
    _put(key, value);
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    _expungeStaleEntries();
    final hashCode = identityHashCode(key);
    final buckets = _buckets;
    final length = buckets.length;
    final index = hashCode & (length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode &&
          identical(entry.keyWeakRef.target, key)) {
        return entry.value!;
      }
      entry = entry.next;
    }
    final stamp = _modificationCount;
    V value = ifAbsent();
    if (stamp == _modificationCount) {
      _addEntry(buckets, index, length, key, value, hashCode);
    } else {
      this[key] = value;
    }
    return value;
  }

  @override
  V? remove(Object? key) {
    _expungeStaleEntries();
    return _remove(key);
  }

  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    _expungeStaleEntries();
    final hashCode = identityHashCode(key);
    final buckets = _buckets;
    final length = buckets.length;
    final index = hashCode & (length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode &&
          identical(entry.keyWeakRef.target, key)) {
        return entry.value = update(entry.value as V);
      }
      entry = entry.next;
    }
    if (ifAbsent != null) {
      V newValue = ifAbsent();
      _addEntry(buckets, index, length, key, newValue, hashCode);
      return newValue;
    } else {
      throw ArgumentError.value(key, "key", "Key not in map.");
    }
  }

  @override
  void _put(K key, V value) {
    final hashCode = identityHashCode(key);
    final buckets = _buckets;
    final length = buckets.length;
    final index = hashCode & (length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode &&
          identical(entry.keyWeakRef.target, key)) {
        entry.value = value;
        return;
      }
      entry = entry.next;
    }
    _addEntry(buckets, index, length, key, value, hashCode);
  }

  @override
  V? _remove(Object? key) {
    if (key == null) return null;
    final hashCode = identityHashCode(key);
    final buckets = _buckets;
    final index = hashCode & (buckets.length - 1);
    var entry = buckets[index];
    _WeakHashMapEntry<K, V>? previous;
    while (entry != null) {
      final next = entry.next;
      if (hashCode == entry.hashCode &&
          identical(entry.keyWeakRef.target, key)) {
        _removeEntry(entry, previous, index);
        _elementCount--;
        _modificationCount =
            (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
        return entry.value;
      }
      previous = entry;
      entry = next;
    }
    return null;
  }
}

mixin _CustomWeakHashMapMixin<K extends Object, V> on WeakHashMapMixin<K, V> {
  bool Function(K, K) get _equals;

  int Function(K) get _hashCode;

  bool Function(Object?) get _validKey;

  @override
  bool containsKey(Object? key) {
    if (!_validKey(key)) return false;
    K lkey = key as K;
    final hashCode = _hashCode(lkey);
    final buckets = _buckets;
    final index = hashCode & (buckets.length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode) {
        final k = entry.keyWeakRef.target;
        if (k != null && _equals(k, lkey)) {
          return true;
        }
      }
      entry = entry.next;
    }
    return false;
  }

  @override
  V? operator [](Object? key) {
    if (key == null || !_validKey(key)) return null;
    _expungeStaleEntries();
    K lkey = key as K;
    final hashCode = _hashCode(lkey);
    final buckets = _buckets;
    final index = hashCode & (buckets.length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode) {
        final k = entry.keyWeakRef.target;
        if (k != null && _equals(k, lkey)) {
          return entry.value;
        }
      }
      entry = entry.next;
    }
    return null;
  }

  @override
  void operator []=(K key, V? value) {
    _expungeStaleEntries();
    if (value == null) {
      _remove(key);
      return;
    }
    _put(key, value);
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    _expungeStaleEntries();
    final hashCode = _hashCode(key);
    final buckets = _buckets;
    final length = buckets.length;
    final index = hashCode & (length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode) {
        final k = entry.keyWeakRef.target;
        if (k != null && _equals(k, key)) {
          return entry.value as V;
        }
      }
      entry = entry.next;
    }
    int stamp = _modificationCount;
    V value = ifAbsent();
    if (stamp == _modificationCount) {
      _addEntry(buckets, index, length, key, value, hashCode);
    } else {
      this[key] = value;
    }
    return value;
  }

  @override
  V? remove(Object? key) {
    if (!_validKey(key)) return null;
    _expungeStaleEntries();
    return _remove(key);
  }

  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    _expungeStaleEntries();
    final hashCode = _hashCode(key);
    final buckets = _buckets;
    final length = buckets.length;
    final index = hashCode & (length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode) {
        final k = entry.keyWeakRef.target;
        if (k != null && _equals(k, key)) {
          return entry.value = update(entry.value as V);
        }
      }
      entry = entry.next;
    }
    if (ifAbsent != null) {
      V newValue = ifAbsent();
      _addEntry(buckets, index, length, key, newValue, hashCode);
      return newValue;
    } else {
      throw ArgumentError.value(key, "key", "Key not in map.");
    }
  }

  @override
  void _put(K key, V value) {
    final hashCode = _hashCode(key);
    final buckets = _buckets;
    final length = buckets.length;
    final index = hashCode & (length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode) {
        final k = entry.keyWeakRef.target;
        if (k != null && _equals(k, key)) {
          entry.value = value;
          return;
        }
      }
      entry = entry.next;
    }
    _addEntry(buckets, index, length, key, value, hashCode);
  }

  @override
  V? _remove(Object? key) {
    if (!_validKey(key)) return null;
    K lkey = key as K;
    final hashCode = _hashCode(lkey);
    final buckets = _buckets;
    final index = hashCode & (buckets.length - 1);
    var entry = buckets[index];
    _WeakHashMapEntry<K, V>? previous;
    while (entry != null) {
      final next = entry.next;
      if (hashCode == entry.hashCode) {
        final k = entry.keyWeakRef.target;
        if (k != null && _equals(k, key)) {
          _removeEntry(entry, previous, index);
          _elementCount--;
          _modificationCount =
              (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
          return entry.value;
        }
      }
      previous = entry;
      entry = next;
    }
    return null;
  }
}

@visibleForTesting
extension WeakHashMapTestExt<K extends Object, V> on WeakHashMap<K, V> {
  int Function(K) get __hashCode => () {
        return this is _IdentityWeakHashMap
            ? identityHashCode
            : this is _CustomWeakHashMap
                ? (this as _CustomWeakHashMap<K, V>)._hashCode
                : defaultHashCode;
      }();

  bool Function(K, K) get __equals => () {
        return this is _IdentityWeakHashMap
            ? identical
            : this is _CustomWeakHashMap
                ? (this as _CustomWeakHashMap<K, V>)._equals
                : defaultEquals;
      }();

  @visibleForTesting
  Object? getWeakEntry(K key) {
    int index = __hashCode(key) & (_buckets.length - 1);
    var entry = _buckets[index];
    while (entry != null) {
      final k = entry.key;
      if (k != null && __equals(key, k)) return entry;
      entry = entry.next;
    }
    return null;
  }

  @visibleForTesting
  int getBucketLength() => _buckets.length;

  @visibleForTesting
  int getNotNullBucketLength() {
    int count = 0;
    for (var entry in _buckets) {
      if (entry != null) count++;
    }
    return count;
  }
}
