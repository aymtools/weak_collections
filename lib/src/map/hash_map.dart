import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:weak_collections/src/set/hash_set.dart';
import 'package:weak_collections/src/tools.dart';

part 'base.dart';
part 'linked_hash_map.dart';

abstract class _WeakHashMapIterator<K extends Object, V, E>
    implements Iterator<E> {
  final WeakHashMap<K, V> _map;
  final int _modificationCount;

  int _index = 0;
  K? _currKey;
  _WeakHashMapEntry<K, V>? _entry;

  _WeakHashMapIterator(this._map)
      : _modificationCount = _map._modificationCount;

  @override
  bool moveNext() {
    if (_modificationCount != _map._modificationCount) {
      throw ConcurrentModificationError(_map);
    }
    _currKey = null;
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
    _entry = null;
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

class WeakHashMap<K extends Object, V>
    with MapMixin<K, V>, WeakHashMapMixin<K, V> {
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
  Iterable<K> get keys {
    _expungeStaleEntries();
    return _WeakHashMapKeyIterable<K, V>(this);
  }

  @override
  Iterable<V> get values {
    _expungeStaleEntries();
    return _WeakHashMapValueIterable<K, V>(this);
  }
}

class _IdentityWeakHashMap<K extends Object, V> extends WeakHashMap<K, V>
    with _IdentityWeakHashMapMixin<K, V> {
  @override
  Set<K> _newKeySet() => WeakHashSet<K>.identity();
}

class _CustomWeakHashMap<K extends Object, V> extends WeakHashMap<K, V>
    with _CustomWeakHashMapMixin<K, V> {
  @override
  final bool Function(K, K) _equals;
  @override
  final int Function(K) _hashCode;
  @override
  final bool Function(Object?) _validKey;

  _CustomWeakHashMap(
      this._equals, this._hashCode, bool Function(Object?)? validKey)
      : _validKey = (validKey != null) ? validKey : TypeTest<K>().test;

  @override
  Set<K> _newKeySet() => WeakHashSet<K>.custom(
      equals: _equals, hashCode: _hashCode, isValidKey: _validKey);
}
