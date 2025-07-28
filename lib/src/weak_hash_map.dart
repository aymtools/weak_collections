import 'dart:collection';

import 'weak_hash_set.dart';

// ignore: constant_identifier_names
const int _MODIFICATION_COUNT_MASK = 0x3fffffff;

class _WeakHashMapEntry<K extends Object, V> {
  final WeakReference<K> key;
  V? value;

  _WeakHashMapEntry<K, V>? next;
  final Finalizer<_WeakHashMapEntry<K, V>> finalizer;

  @override
  final int hashCode;

  _WeakHashMapEntry(
    K key,
    this.value,
    this.hashCode,
    this.next,
    this.finalizer,
  ) : key = WeakReference(key) {
    finalizer.attach(key, this);
  }

  _WeakHashMapEntry<K, V>? remove() {
    finalizer.detach(this);
    final result = next;
    next = null;
    return result;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other);
  }
}

abstract class _WeakHashMapIterator<K extends Object, V, E>
    implements Iterator<E> {
  final WeakHashMap<K, V> _map;
  final int _stamp;

  int _index = 0;
  K? _currKey;
  _WeakHashMapEntry<K, V>? _entry;

  _WeakHashMapIterator(this._map) : _stamp = _map._modificationCount;

  @override
  bool moveNext() {
    _currKey = null;
    if (_stamp != _map._modificationCount) {
      throw ConcurrentModificationError(_map);
    }
    var entry = _entry?.next;
    while (entry != null) {
      K? key = entry.key.target;
      if (key != null) {
        _currKey = key; // 引用一下阻止回收
        _entry = entry;
        return true;
      }
      entry = entry.next;
    }

    final buckets = _map._buckets;
    final length = buckets.length;
    for (int i = _index; i < length; i++) {
      entry = buckets[i];
      _index = i + 1;
      while (entry != null) {
        K? key = entry.key.target;
        if (key != null) {
          _currKey = key; // 引用一下阻止回收
          _entry = entry;
          return true;
        }
        entry = entry.next;
      }
    }
    _index = length;
    return false;
  }
}

class _WeakHashMapKeyIterator<K extends Object, V>
    extends _WeakHashMapIterator<K, V, K> {
  _WeakHashMapKeyIterator(super.map);

  @override
  K get current => _currKey!;
}

class _WeakHashMapValueIterator<K extends Object, V>
    extends _WeakHashMapIterator<K, V, V> {
  _WeakHashMapValueIterator(super.map);

  @override
  V get current => _entry!.value!;
}

abstract class _WeakHashMapIterable<K extends Object, V, E>
    extends Iterable<E> {
  final WeakHashMap<K, V> _map;

  _WeakHashMapIterable(this._map);

  @override
  int get length => _map.length;

  @override
  bool get isEmpty => _map.isEmpty;

  @override
  bool get isNotEmpty => _map.isNotEmpty;
}

class _WeakHashMapKeyIterable<K extends Object, V>
    extends _WeakHashMapIterable<K, V, K> {
  _WeakHashMapKeyIterable(super.map);

  @override
  Iterator<K> get iterator => _WeakHashMapKeyIterator<K, V>(_map);

  @override
  bool contains(Object? key) => _map.containsKey(key);

  @override
  void forEach(void Function(K key) action) {
    _map.forEach((K key, _) {
      action(key);
    });
  }

  @override
  Set<K> toSet() => _map._newKeySet()..addAll(this);
}

class _WeakHashMapValueIterable<K extends Object, V>
    extends _WeakHashMapIterable<K, V, V> {
  _WeakHashMapValueIterable(super.map);

  @override
  Iterator<V> get iterator => _WeakHashMapValueIterator<K, V>(_map);

  @override
  bool contains(Object? value) => _map.containsValue(value);

  @override
  void forEach(void Function(V value) action) {
    _map.forEach((_, V value) {
      action(value);
    });
  }
}

class WeakHashMap<K extends Object, V> with MapMixin<K, V> {
  // ignore: constant_identifier_names
  static const int _INITIAL_CAPACITY = 8;

  final Queue<_WeakHashMapEntry<K, V>> _queue = Queue();
  late final Finalizer<_WeakHashMapEntry<K, V>> _finalizer =
      Finalizer((entry) => _queue.add(entry..value = null));

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
  Iterable<K> get keys {
    _expungeStaleEntries();
    return _WeakHashMapKeyIterable<K, V>(this);
  }

  @override
  Iterable<V> get values {
    _expungeStaleEntries();
    return _WeakHashMapValueIterable<K, V>(this);
  }

  @override
  Iterable<MapEntry<K, V>> get entries {
    _expungeStaleEntries();
    return super.entries;
  }

  void _expungeStaleEntries() {
    if (_queue.isEmpty) return;
    _WeakHashMapEntry<K, V> e;
    while (_queue.isNotEmpty) {
      e = _queue.removeFirst();
      int index = e.hashCode & (_buckets.length - 1);
      var entry = _buckets[index];
      if (entry == null) continue;
      if (entry == e) {
        _buckets[index] = e.next;
        _elementCount--;
      } else {
        _WeakHashMapEntry<K, V>? c;
        while ((c = entry?.next) != null) {
          if (c == e) {
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

  // void __() {
  //   var count = _elementCount;
  //   for (int i = 0; i < _buckets.length; i++) {
  //     var entry = _buckets[i];
  //     if (entry != null) {
  //       _WeakHashMapEntry<K, V>? c = entry;
  //       while (c != null && c.key.target == null) {
  //         c = c.remove();
  //         _elementCount--;
  //       }
  //       if (c != entry) _buckets[i] = c;
  //       if (c != null) {
  //         while (c != null) {
  //           while (c.next != null && c.next?.key.target == null) {
  //             c.next = c.next!.remove();
  //             _elementCount--;
  //           }
  //           c = c.next;
  //         }
  //       }
  //     }
  //   }
  //   if (_elementCount != count) {
  //     _modificationCount = (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
  //   }
  // }

  @override
  bool containsKey(Object? key) {
    if (key == null) return false;
    final hashCode = key.hashCode;
    final buckets = _buckets;
    final index = hashCode & (buckets.length - 1);
    var entry = buckets[index];
    while (entry != null) {
      if (hashCode == entry.hashCode && entry.key.target == key) return true;
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
        if (entry.key.target != null && entry.value == value) return true;
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
      if (hashCode == entry.hashCode && entry.key.target == key) {
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
      if (hashCode == entry.hashCode && entry.key.target == key) {
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
      if (hashCode == entry.hashCode && entry.key.target == key) {
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
        K? k = entry.key.target;
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
      if (hashCode == entry.hashCode && entry.key.target == key) {
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
      _buckets[bucketIndex] = entry.next;
    } else {
      previousInBucket.next = entry.next;
    }
  }

  void _addEntry(List<_WeakHashMapEntry<K, V>?> buckets, int index, int length,
      K key, V value, int hashCode) {
    final entry = _WeakHashMapEntry<K, V>(
        key, value, hashCode, buckets[index], _finalizer);
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
      if (hashCode == entry.hashCode && entry.key.target == key) {
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
        K? k = entry.key.target;
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
    Set<K> set = WeakHashSet();
    return set;
  }
}
