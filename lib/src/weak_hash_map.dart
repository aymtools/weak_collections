import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:weak_collections/src/tools.dart';

import 'weak_hash_set.dart';

// ignore: constant_identifier_names
const int _MODIFICATION_COUNT_MASK = 0x3fffffff;

class _WeakHashMapEntry<K extends Object, V> {
  final WeakReference<K> keyWeakRef;
  V? value;

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
      K? key = entry.keyWeakRef.target;
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
        K? key = entry.keyWeakRef.target;
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

  // final Queue<WeakReference<_WeakHashMapEntry<K, V>>> _queue = Queue();
  //
  // late final Finalizer<WeakReference<_WeakHashMapEntry<K, V>>> _finalizer =
  //     Finalizer((entry) {
  //   if (entry.target != null) {
  //     entry.target?.value = null;
  //     _queue.add(entry);
  //   }
  // });

  final WeakReferenceQueue<K, _WeakHashMapEntry<K, V>> _queue =
      WeakReferenceQueue();

  int _elementCount = 0;
  var _buckets = List<_WeakHashMapEntry<K, V>?>.filled(_INITIAL_CAPACITY, null);
  int _modificationCount = 0;

  WeakHashMap();

  factory WeakHashMap.identity() => _IdentityWeakHashMap<K, V>();

  factory WeakHashMap.from(Map<dynamic, dynamic> other) {
    WeakHashMap<K, V> result = WeakHashMap<K, V>();
    other.forEach((dynamic k, dynamic v) {
      result[k as K] = v as V;
    });
    return result;
  }

  factory WeakHashMap.of(Map<K, V> other) => WeakHashMap<K, V>()..addAll(other);

  factory WeakHashMap.fromIterable(Iterable iterable,
      {K Function(dynamic element)? key, V Function(dynamic element)? value}) {
    final map = WeakHashMap<K, V>();
    key ??= unsafeCast<K>;
    value ??= unsafeCast<V>;
    for (final e in iterable) {
      map[key(e)] = value(e);
    }
    return map;
  }

  factory WeakHashMap.fromIterables(Iterable<K> keys, Iterable<V> values) {
    final map = WeakHashMap<K, V>();
    Iterator<K> keyIterator = keys.iterator;
    Iterator<V> valueIterator = values.iterator;

    bool hasNextKey = keyIterator.moveNext();
    bool hasNextValue = valueIterator.moveNext();

    while (hasNextKey && hasNextValue) {
      map[keyIterator.current] = valueIterator.current;
      hasNextKey = keyIterator.moveNext();
      hasNextValue = valueIterator.moveNext();
    }

    if (hasNextKey || hasNextValue) {
      throw ArgumentError("Iterables do not have same length.");
    }
    return map;
  }

  factory WeakHashMap.fromEntries(Iterable<MapEntry<K, V>> entries) =>
      WeakHashMap<K, V>()..addEntries(entries);

  factory WeakHashMap.custom({
    bool Function(K, K)? equals,
    int Function(K)? hashCode,
    bool Function(dynamic)? isValidKey,
  }) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return WeakHashMap<K, V>();
        }
        hashCode = defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return _IdentityWeakHashMap<K, V>();
        }
        equals ??= defaultEquals;
      }
    } else {
      hashCode ??= defaultHashCode;
      equals ??= defaultEquals;
    }
    return _CustomWeakHashMap<K, V>(equals, hashCode, isValidKey);
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
    // _WeakHashMapEntry<K, V> e;
    // while (_queue.isNotEmpty) {
    //   final entryQ = _queue.removeFirst().target;
    //   if (entryQ == null) continue;
    //   e = entryQ;
    //
    //   int index = e.hashCode & (_buckets.length - 1);
    //   var entry = _buckets[index];
    //   if (entry == null) continue;
    //   if (entry == e) {
    //     _buckets[index] = e.next;
    //     _elementCount--;
    //   } else {
    //     _WeakHashMapEntry<K, V>? c;
    //     while ((c = entry?.next) != null) {
    //       if (c == e) {
    //         entry?.next = e.remove();
    //         _elementCount--;
    //         break;
    //       }
    //       entry = c;
    //     }
    //   }
    // }
    final count = _elementCount;
    _queue.expungeStale((e) {
      int index = e.hashCode & (_buckets.length - 1);
      var entry = _buckets[index];
      if (entry != null) {
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
    });
    if (_elementCount != count) {
      _modificationCount = (_modificationCount + 1) & _MODIFICATION_COUNT_MASK;
    }
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
    final entry =
        _WeakHashMapEntry<K, V>(key, value, hashCode, buckets[index], _queue);
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
    Set<K> set = WeakHashSet();
    return set;
  }
}

class _IdentityWeakHashMap<K extends Object, V> extends WeakHashMap<K, V> {
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

  @override
  Set<K> _newKeySet() => WeakHashSet<K>();
}

class _CustomWeakHashMap<K extends Object, V> extends WeakHashMap<K, V> {
  final bool Function(K, K) _equals;
  final int Function(K) _hashCode;
  final bool Function(Object?) _validKey;

  _CustomWeakHashMap(
      this._equals, this._hashCode, bool Function(Object?)? validKey)
      : _validKey = (validKey != null) ? validKey : TypeTest<K>().test;

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

  @override
  Set<K> _newKeySet() => WeakHashSet<K>();
}

@visibleForTesting
extension WeakHashMapTestExt<K extends Object, V> on WeakHashMap<K, V> {
  get __hashCode => () {
        return this is _IdentityWeakHashMap
            ? identityHashCode
            : this is _CustomWeakHashMap
                ? (this as _CustomWeakHashMap<K, V>)._hashCode
                : defaultHashCode;
      }();

  get __equals => () {
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
      if (__equals(key, entry.keyWeakRef.target)) return entry;
      entry = entry.next;
    }
    return null;
  }

  @visibleForTesting
  int getBucketLength() => _buckets.length;
}
