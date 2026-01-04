part of 'hash_map.dart';

class _WeakLinkedHashMapEntry<K extends Object, V>
    extends _WeakHashMapEntry<K, V> {
  WeakLinkedNode<_WeakLinkedHashMapEntry<K, V>>? node;

  _WeakLinkedHashMapEntry(
      super.key, super.value, super.hashCode, super.next, super.queue) {
    node = WeakLinkedNode(this);
  }

  @override
  _WeakHashMapEntry<K, V>? remove() {
    node = null;
    return super.remove();
  }
}

abstract class _WeakLinkedHashMapIterator<K extends Object, V, E>
    implements Iterator<E> {
  final WeakLinkedHashMap<K, V> _map;
  final int _modificationCount;

  WeakLinkedNode<_WeakLinkedHashMapEntry<K, V>>? _next;
  K? _currKey;
  _WeakLinkedHashMapEntry<K, V>? _current;

  _WeakLinkedHashMapIterator(this._map)
      : _modificationCount = _map._modificationCount,
        _next = _map._head;

  @override
  bool moveNext() {
    if (_modificationCount != _map._modificationCount) {
      throw ConcurrentModificationError(_map);
    }
    _currKey = null;
    _current = null;

    var localNext = _next;
    while (localNext != null) {
      var key = localNext.value.key;
      if (key != null) {
        _currKey = key;
        _current = localNext.value;
        _next = localNext.next;
        return true;
      }
      localNext = localNext.next;
    }
    return false;
  }
}

class _WeakLinkedHashMapKeyIterator<K extends Object, V>
    extends _WeakLinkedHashMapIterator<K, V, K> {
  _WeakLinkedHashMapKeyIterator(super.map);

  @override
  K get current => _currKey!;
}

class _WeakLinkedHashMapValueIterator<K extends Object, V>
    extends _WeakLinkedHashMapIterator<K, V, V> {
  _WeakLinkedHashMapValueIterator(super.map);

  @override
  V get current => _current!.value!;
}

abstract class _WeakLinkedHashMapIterable<K extends Object, V, E>
    extends _WeakHashMapIterable<K, V, E> {
  final WeakLinkedHashMap<K, V> _linkedHashMap;

  _WeakLinkedHashMapIterable(this._linkedHashMap) : super(_linkedHashMap);

  @override
  WeakLinkedHashMap<K, V> get _map => _linkedHashMap;
}

class _WeakLinkedHashMapKeyIterable<K extends Object, V>
    extends _WeakLinkedHashMapIterable<K, V, K> {
  _WeakLinkedHashMapKeyIterable(super.map);

  @override
  Iterator<K> get iterator => _WeakLinkedHashMapKeyIterator<K, V>(_map);

  @override
  bool contains(Object? key) => _map.containsKey(key);

  @override
  Set<K> toSet() => _map._newKeySet()..addAll(this);
}

class _WeakLinkedHashMapValueIterable<K extends Object, V>
    extends _WeakLinkedHashMapIterable<K, V, V> {
  _WeakLinkedHashMapValueIterable(super.map);

  @override
  bool contains(Object? value) => _map.containsValue(value);

  @override
  Iterator<V> get iterator => _WeakLinkedHashMapValueIterator<K, V>(_map);
}

class _MapEntry<K extends Object, V> implements MapEntry<K, V> {
  @override
  final K key;
  @override
  final V value;

  _MapEntry(this.key, this.value);
}

class _WeakLinkedHashMapEntryIterator<K extends Object, V>
    extends Iterator<MapEntry<K, V>> {
  final WeakLinkedHashMap<K, V> _map;
  final int _modificationCount;

  WeakLinkedNode<_WeakLinkedHashMapEntry<K, V>>? _next;

  MapEntry<K, V>? _current;

  _WeakLinkedHashMapEntryIterator(this._map)
      : _modificationCount = _map._modificationCount,
        _next = _map._head;

  @override
  bool moveNext() {
    if (_modificationCount != _map._modificationCount) {
      throw ConcurrentModificationError(_map);
    }
    _current = null;
    var localNext = _next;
    while (localNext != null) {
      var key = localNext.value.key;
      if (key != null) {
        _current = _MapEntry(key, localNext.value.value as V);
        _next = localNext.next;
        return true;
      }
      localNext = localNext.next;
    }
    return false;
  }

  @override
  MapEntry<K, V> get current => _current!;
}

class _WeakLinkedHashMapEntryIterable<K extends Object, V>
    extends Iterable<MapEntry<K, V>> {
  final WeakLinkedHashMap<K, V> _map;

  _WeakLinkedHashMapEntryIterable(this._map);

  @override
  Iterator<MapEntry<K, V>> get iterator =>
      _WeakLinkedHashMapEntryIterator<K, V>(_map);
}

class WeakLinkedHashMap<K extends Object, V> extends WeakHashMap<K, V>
    implements LinkedHashMap<K, V> {
  WeakLinkedNode<_WeakLinkedHashMapEntry<K, V>>? _head;
  WeakLinkedNode<_WeakLinkedHashMapEntry<K, V>>? _tail;

  WeakLinkedHashMap();

  factory WeakLinkedHashMap.identity() => _IdentityWeakLinkedHashMap<K, V>();

  factory WeakLinkedHashMap.from(Map<dynamic, dynamic> other) {
    WeakLinkedHashMap<K, V> result = WeakLinkedHashMap<K, V>();
    other.forEach((dynamic k, dynamic v) {
      result[k as K] = v as V;
    });
    return result;
  }

  factory WeakLinkedHashMap.of(Map<K, V> other) =>
      WeakLinkedHashMap<K, V>()..addAll(other);

  factory WeakLinkedHashMap.fromIterable(Iterable iterable,
      {K Function(dynamic element)? key, V Function(dynamic element)? value}) {
    final map = WeakLinkedHashMap<K, V>();
    key ??= unsafeCast<K>;
    value ??= unsafeCast<V>;
    for (final e in iterable) {
      map[key(e)] = value(e);
    }
    return map;
  }

  factory WeakLinkedHashMap.fromIterables(
      Iterable<K> keys, Iterable<V> values) {
    final map = WeakLinkedHashMap<K, V>();
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

  factory WeakLinkedHashMap.fromEntries(Iterable<MapEntry<K, V>> entries) =>
      WeakLinkedHashMap<K, V>()..addEntries(entries);

  factory WeakLinkedHashMap.custom({
    bool Function(K, K)? equals,
    int Function(K)? hashCode,
    bool Function(dynamic)? isValidKey,
  }) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return WeakLinkedHashMap<K, V>();
        }
        hashCode = defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return _IdentityWeakLinkedHashMap<K, V>();
        }
        equals ??= defaultEquals;
      }
    } else {
      hashCode ??= defaultHashCode;
      equals ??= defaultEquals;
    }
    return _CustomWeakLinkedHashMap<K, V>(equals, hashCode, isValidKey);
  }

  @override
  Iterable<K> get keys {
    _expungeStaleEntries();
    return _WeakLinkedHashMapKeyIterable<K, V>(this);
  }

  @override
  Iterable<V> get values {
    _expungeStaleEntries();
    return _WeakLinkedHashMapValueIterable<K, V>(this);
  }

  @override
  Iterable<MapEntry<K, V>> get entries {
    _expungeStaleEntries();
    return _WeakLinkedHashMapEntryIterable(this);
  }

  @override
  void forEach(void Function(K key, V value) action) {
    _expungeStaleEntries();
    final stamp = _modificationCount;
    var entry = _head;
    while (entry != null) {
      K? k = entry.value.key;
      if (k != null) {
        action(k, entry.value.value as V);
      }
      if (stamp != _modificationCount) {
        throw ConcurrentModificationError(this);
      }
      entry = entry.next;
    }
  }

  @override
  _WeakHashMapEntry<K, V> _makeEntry(
      K key,
      V value,
      int hashCode,
      _WeakHashMapEntry<K, V>? next,
      WeakReferenceQueue<K, _WeakHashMapEntry<K, V>>? queue) {
    final entry =
        _WeakLinkedHashMapEntry<K, V>(key, value, hashCode, next, queue);
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
  void _removeEntry(_WeakHashMapEntry<K, V> entry,
      _WeakHashMapEntry<K, V>? previousInBucket, int bucketIndex) {
    final node = (entry as _WeakLinkedHashMapEntry<K, V>).node;
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
  Set<K> _newKeySet() {
    Set<K> set = WeakLinkedHashSet<K>();
    return set;
  }
}

class _IdentityWeakLinkedHashMap<K extends Object, V>
    extends WeakLinkedHashMap<K, V> with _IdentityWeakHashMapMixin<K, V> {
  @override
  Set<K> _newKeySet() {
    Set<K> set = WeakLinkedHashSet<K>.identity();
    return set;
  }
}

class _CustomWeakLinkedHashMap<K extends Object, V>
    extends WeakLinkedHashMap<K, V> with _CustomWeakHashMapMixin<K, V> {
  @override
  final bool Function(K, K) _equals;
  @override
  final int Function(K) _hashCode;
  @override
  final bool Function(Object?) _validKey;

  _CustomWeakLinkedHashMap(
      this._equals, this._hashCode, bool Function(Object?)? validKey)
      : _validKey = (validKey != null) ? validKey : TypeTest<K>().test;

  @override
  Set<K> _newKeySet() => WeakLinkedHashSet<K>.custom(
      equals: _equals, hashCode: _hashCode, isValidKey: _validKey);
}

@visibleForTesting
extension WeakLinkedHashMapTestExt<K extends Object, V>
    on WeakLinkedHashMap<K, V> {
  @visibleForTesting
  bool get headEqNull => _head == null;

  @visibleForTesting
  bool get tailEqNull => _tail == null;

  @visibleForTesting
  bool get headEqTail => _head == _tail;

  @visibleForTesting
  K? get headKey => _head?.value.key;

  @visibleForTesting
  K? get tailKey => _tail?.value.key;

  @visibleForTesting
  V? get headValue => _head?.value.value;

  @visibleForTesting
  V? get tailValue => _tail?.value.value;
}
