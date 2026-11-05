part of 'hash_map.dart';

/// 混杂模式 HashMap 节点 Entry。
///
/// 当 [isWeak] 为 `true` 时，Key 借由父类的 `WeakReference` + `WeakReferenceQueue` 管理弱引用；
/// 当 [isWeak] 为 `false` 时，Key 在 [_strongKey] 中持有强引用，且不向 Finalizer 队列注册，保证 Key 不被 GC 自动清理。
class _MixedHashMapEntry<K extends Object, V>
    extends _WeakHashMapEntry<K, V> {
  final K? _strongKey;
  final bool isWeakRef;

  _MixedHashMapEntry(
    K key,
    V value,
    int hashCode,
    _WeakHashMapEntry<K, V>? next,
    WeakReferenceQueue<K, _WeakHashMapEntry<K, V>>? queue,
    bool isWeak,
  )   : isWeakRef = isWeak,
        _strongKey = isWeak ? null : key,
        super(
          key,
          value,
          hashCode,
          next,
          isWeak ? queue : null,
        );

  @override
  K? get key => _strongKey ?? super.key;
}

/// 混杂模式 LinkedHashMap 节点 Entry。
///
/// 继承自 [_WeakLinkedHashMapEntry]，用于在混杂 Key 引用模式下同时维护双向链表节点。
class _MixedLinkedHashMapEntry<K extends Object, V>
    extends _WeakLinkedHashMapEntry<K, V> {
  final K? _strongKey;
  final bool isWeakRef;

  _MixedLinkedHashMapEntry(
    K key,
    V value,
    int hashCode,
    _WeakHashMapEntry<K, V>? next,
    WeakReferenceQueue<K, _WeakHashMapEntry<K, V>>? queue,
    bool isWeak,
  )   : isWeakRef = isWeak,
        _strongKey = isWeak ? null : key,
        super(
          key,
          value,
          hashCode,
          next,
          isWeak ? queue : null,
        );

  @override
  K? get key => _strongKey ?? super.key;
}

/// 混杂模式 Key 弱引用 Map Mixin。
///
/// 混杂模式允许向 Map 中存入键值对时显式或隐式地指定 Key 为**弱引用**还是**强引用**。
mixin MixedRefHashMapMixin<K extends Object, V> on WeakHashMapMixin<K, V> {
  /// 构造函数中传入的 Key 引用类型决策谓词，若为 `null` 则默认采用弱引用 Key。
  bool Function(K)? get _isWeakKeyPredicate => null;

  bool? _pendingIsWeakKey;

  int _keyHashCode(K key) {
    if (this is _IdentityWeakHashMapMixin) {
      return identityHashCode(key);
    }
    if (this is _CustomWeakHashMapMixin) {
      return (this as _CustomWeakHashMapMixin<K, V>)._hashCode(key);
    }
    return key.hashCode;
  }

  bool _keyEquals(K k1, K k2) {
    if (this is _IdentityWeakHashMapMixin) {
      return identical(k1, k2);
    }
    if (this is _CustomWeakHashMapMixin) {
      return (this as _CustomWeakHashMapMixin<K, V>)._equals(k1, k2);
    }
    return k1 == k2;
  }

  /// 解析指定键 [key] 的引用模式。
  bool _resolveIsWeakKey(K key, bool? isWeak) {
    if (isWeak != null) return isWeak;
    final predicate = _isWeakKeyPredicate;
    if (predicate != null) return predicate(key);
    return true;
  }

  /// 向 Map 中设置键值对，允许显式指定 [isWeakKey] 控制 Key 的强弱引用模式。
  ///
  /// - [isWeakKey] 为 `true` 时，Key 以**弱引用**形式保存（Key 被 GC 后自动移除该 Entry）。
  /// - [isWeakKey] 为 `false` 时，Key 以**强引用**形式保存（常驻内存，直到手动 remove）。
  /// - [isWeakKey] 为 `null` 时，使用默认引用策略（构造时传入的 [_isWeakKeyPredicate] 或默认弱引用）。
  /// - 如果 Key 已存在但当前的引用模式与目标 [isWeakKey] 不一致，会自动升级/转换为目标的引用模式。
  void put(K key, V value, {bool? isWeakKey}) {
    _expungeStaleEntries();
    _putWithRef(key, value, isWeakKey: isWeakKey);
  }

  /// 以 Key **弱引用**形式设置键值对。
  void putWeakKey(K key, V value) => put(key, value, isWeakKey: true);

  /// 以 Key **强引用**形式设置键值对。
  void putStrongKey(K key, V value) => put(key, value, isWeakKey: false);

  /// 内部带 Key 引用模式处理的键值对设置实现。
  void _putWithRef(K key, V value, {bool? isWeakKey}) {
    final hashCode = _keyHashCode(key);
    final buckets = _buckets;
    final length = buckets.length;
    final index = hashCode & (length - 1);
    var entry = buckets[index];
    _WeakHashMapEntry<K, V>? previous;

    final targetIsWeak = _resolveIsWeakKey(key, isWeakKey);

    while (entry != null) {
      if (hashCode == entry.hashCode) {
        final k = entry.key;
        if (k != null && _keyEquals(k, key)) {
          if (entry is _MixedHashMapEntry<K, V>) {
            if (entry.isWeakRef != targetIsWeak) {
              // Key 已存在但引用模式不同，替换节点以升级/转换 Key 的引用模式
              final newEntry = _makeMixedEntry(
                  key, value, hashCode, entry.next, _queue, targetIsWeak);
              if (previous == null) {
                buckets[index] = newEntry;
              } else {
                previous.next = newEntry;
              }
              entry.remove();
              return;
            }
          }
          entry.value = value;
          return;
        }
      }
      previous = entry;
      entry = entry.next;
    }

    try {
      _pendingIsWeakKey = targetIsWeak;
      _addEntry(buckets, index, length, key, value, hashCode);
    } finally {
      _pendingIsWeakKey = null;
    }
  }

  /// 创建带强弱引用标志的混杂 Entry 节点。
  _WeakHashMapEntry<K, V> _makeMixedEntry(
      K key,
      V value,
      int hashCode,
      _WeakHashMapEntry<K, V>? next,
      WeakReferenceQueue<K, _WeakHashMapEntry<K, V>> queue,
      bool isWeak) {
    return _MixedHashMapEntry<K, V>(
        key, value, hashCode, next, queue, isWeak);
  }

  /// 模板方法：在底层被 [WeakHashMapMixin] 的内部逻辑或 Dart 标准 `Map` 接口（如 `map[key] = value`、`map.addAll(...)` 等）调用。
  ///
  /// **注意点**：此处**绝不能直接抛出异常**！
  /// 因为 Dart 标准 `Map` 接口的方法（如 `map[key] = value`、`map.addAll(...)` 等）
  /// 在底层均依赖 `_makeEntry` 构建节点。
  /// 此处通过 `_resolveIsWeakKey(key, _pendingIsWeakKey)` 降级使用默认策略（弱引用或谓词控制）生成混杂节点，
  /// 既保证了兼容 Dart 标准 `Map` API，又不会破坏混杂模式功能。
  @override
  _WeakHashMapEntry<K, V> _makeEntry(
          K key,
          V value,
          int hashCode,
          _WeakHashMapEntry<K, V>? next,
          WeakReferenceQueue<K, _WeakHashMapEntry<K, V>>? queue) =>
      _makeMixedEntry(
          key,
          value,
          hashCode,
          next,
          queue ?? _queue,
          _resolveIsWeakKey(key, _pendingIsWeakKey));

  @override
  void _removeEntry(_WeakHashMapEntry<K, V> entry,
      _WeakHashMapEntry<K, V>? previousInBucket, int bucketIndex) {
    if (previousInBucket == null) {
      _buckets[bucketIndex] = entry.remove();
    } else {
      previousInBucket.next = entry.remove();
    }
  }
}

/// 混杂模式 Key 弱引用 HashMap 实现类。
///
/// 允许按需指定 Key 为弱引用或强引用保存键值对。
class MixedRefHashMap<K extends Object, V> extends WeakHashMap<K, V>
    with MixedRefHashMapMixin<K, V> {
  @override
  final bool Function(K)? _isWeakKeyPredicate;

  /// 构造一个 [MixedRefHashMap]，可选传入 [isWeakKey] 决策谓词。
  MixedRefHashMap({bool Function(K)? isWeakKey})
      : _isWeakKeyPredicate = isWeakKey;

  /// 构造一个使用 Identity（`identical` 与 `identityHashCode`）比较 Key 的 [MixedRefHashMap]。
  factory MixedRefHashMap.identity({bool Function(K)? isWeakKey}) =>
      _IdentityMixedRefHashMap<K, V>(isWeakKey: isWeakKey);

  /// 从已有 Map [other] 创建 [MixedRefHashMap]。
  factory MixedRefHashMap.from(Map<dynamic, dynamic> other,
      {bool Function(K)? isWeakKey}) {
    MixedRefHashMap<K, V> result = MixedRefHashMap<K, V>(isWeakKey: isWeakKey);
    other.forEach((dynamic k, dynamic v) {
      result[k as K] = v as V;
    });
    return result;
  }

  /// 从已有 Map [other] 创建 [MixedRefHashMap]。
  factory MixedRefHashMap.of(Map<K, V> other, {bool Function(K)? isWeakKey}) =>
      MixedRefHashMap<K, V>(isWeakKey: isWeakKey)..addAll(other);

  /// 从已有 Entry 集合 [entries] 创建 [MixedRefHashMap]。
  factory MixedRefHashMap.fromEntries(Iterable<MapEntry<K, V>> entries,
          {bool Function(K)? isWeakKey}) =>
      MixedRefHashMap<K, V>(isWeakKey: isWeakKey)..addEntries(entries);

  /// 构造一个带有自定义 [equals]、[hashCode]、[isValidKey] 与 [isWeakKey] 的 [MixedRefHashMap]。
  factory MixedRefHashMap.custom({
    bool Function(K, K)? equals,
    int Function(K)? hashCode,
    bool Function(dynamic)? isValidKey,
    bool Function(K)? isWeakKey,
  }) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return MixedRefHashMap<K, V>(isWeakKey: isWeakKey);
        }
        hashCode = defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return _IdentityMixedRefHashMap<K, V>(isWeakKey: isWeakKey);
        }
        equals ??= defaultEquals;
      }
    } else {
      hashCode ??= defaultHashCode;
      equals ??= defaultEquals;
    }
    return _CustomMixedRefHashMap<K, V>(
        equals, hashCode, isValidKey, isWeakKey);
  }

  @override
  Set<K> _newKeySet() => WeakHashSet<K>();
}

class _IdentityMixedRefHashMap<K extends Object, V>
    extends MixedRefHashMap<K, V> with _IdentityWeakHashMapMixin<K, V> {
  _IdentityMixedRefHashMap({super.isWeakKey});

  @override
  Set<K> _newKeySet() => WeakHashSet<K>.identity();
}

class _CustomMixedRefHashMap<K extends Object, V>
    extends MixedRefHashMap<K, V> with _CustomWeakHashMapMixin<K, V> {
  @override
  final bool Function(K, K) _equals;
  @override
  final int Function(K) _hashCode;
  @override
  final bool Function(Object?) _validKey;

  _CustomMixedRefHashMap(
      this._equals, this._hashCode, bool Function(Object?)? validKey,
      [bool Function(K)? isWeakKey])
      : _validKey = (validKey != null) ? validKey : TypeTest<K>().test,
        super(isWeakKey: isWeakKey);

  @override
  Set<K> _newKeySet() => WeakHashSet<K>.custom(
      equals: _equals, hashCode: _hashCode, isValidKey: _validKey);
}

/// [MixedRefHashMap] 的类型别名。
typedef MixedWeakHashMap<K extends Object, V> = MixedRefHashMap<K, V>;

/// [MixedRefHashMap] 的类型别名。
typedef MixedHashMap<K extends Object, V> = MixedRefHashMap<K, V>;

/// 混杂模式 Key 弱引用 LinkedHashMap 实现类。
///
/// 在混杂 Key 引用的基础上保留键值对的插入顺序。
class MixedRefLinkedHashMap<K extends Object, V>
    extends WeakLinkedHashMap<K, V> with MixedRefHashMapMixin<K, V> {
  @override
  final bool Function(K)? _isWeakKeyPredicate;

  /// 构造一个 [MixedRefLinkedHashMap]，可选传入 [isWeakKey] 决策谓词。
  MixedRefLinkedHashMap({bool Function(K)? isWeakKey})
      : _isWeakKeyPredicate = isWeakKey;

  /// 构造一个使用 Identity 比较 Key 的 [MixedRefLinkedHashMap]。
  factory MixedRefLinkedHashMap.identity({bool Function(K)? isWeakKey}) =>
      _IdentityMixedRefLinkedHashMap<K, V>(isWeakKey: isWeakKey);

  /// 从已有 Map [other] 创建 [MixedRefLinkedHashMap]。
  factory MixedRefLinkedHashMap.from(Map<dynamic, dynamic> other,
      {bool Function(K)? isWeakKey}) {
    MixedRefLinkedHashMap<K, V> result =
        MixedRefLinkedHashMap<K, V>(isWeakKey: isWeakKey);
    other.forEach((dynamic k, dynamic v) {
      result[k as K] = v as V;
    });
    return result;
  }

  /// 从已有 Map [other] 创建 [MixedRefLinkedHashMap]。
  factory MixedRefLinkedHashMap.of(Map<K, V> other,
          {bool Function(K)? isWeakKey}) =>
      MixedRefLinkedHashMap<K, V>(isWeakKey: isWeakKey)..addAll(other);

  /// 从已有 Entry 集合 [entries] 创建 [MixedRefLinkedHashMap]。
  factory MixedRefLinkedHashMap.fromEntries(Iterable<MapEntry<K, V>> entries,
          {bool Function(K)? isWeakKey}) =>
      MixedRefLinkedHashMap<K, V>(isWeakKey: isWeakKey)..addEntries(entries);

  /// 构造一个带有自定义比较器的 [MixedRefLinkedHashMap]。
  factory MixedRefLinkedHashMap.custom({
    bool Function(K, K)? equals,
    int Function(K)? hashCode,
    bool Function(dynamic)? isValidKey,
    bool Function(K)? isWeakKey,
  }) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return MixedRefLinkedHashMap<K, V>(isWeakKey: isWeakKey);
        }
        hashCode = defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return _IdentityMixedRefLinkedHashMap<K, V>(isWeakKey: isWeakKey);
        }
        equals ??= defaultEquals;
      }
    } else {
      hashCode ??= defaultHashCode;
      equals ??= defaultEquals;
    }
    return _CustomMixedRefLinkedHashMap<K, V>(
        equals, hashCode, isValidKey, isWeakKey);
  }

  @override
  _WeakHashMapEntry<K, V> _makeMixedEntry(
      K key,
      V value,
      int hashCode,
      _WeakHashMapEntry<K, V>? next,
      WeakReferenceQueue<K, _WeakHashMapEntry<K, V>> queue,
      bool isWeak) {
    final entry = _MixedLinkedHashMapEntry<K, V>(
        key, value, hashCode, next, queue, isWeak);
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
  Set<K> _newKeySet() => WeakLinkedHashSet<K>();
}

class _IdentityMixedRefLinkedHashMap<K extends Object, V>
    extends MixedRefLinkedHashMap<K, V>
    with _IdentityWeakHashMapMixin<K, V> {
  _IdentityMixedRefLinkedHashMap({super.isWeakKey});

  @override
  Set<K> _newKeySet() => WeakLinkedHashSet<K>.identity();
}

class _CustomMixedRefLinkedHashMap<K extends Object, V>
    extends MixedRefLinkedHashMap<K, V>
    with _CustomWeakHashMapMixin<K, V> {
  @override
  final bool Function(K, K) _equals;
  @override
  final int Function(K) _hashCode;
  @override
  final bool Function(Object?) _validKey;

  _CustomMixedRefLinkedHashMap(
      this._equals, this._hashCode, bool Function(Object?)? validKey,
      [bool Function(K)? isWeakKey])
      : _validKey = (validKey != null) ? validKey : TypeTest<K>().test,
        super(isWeakKey: isWeakKey);

  @override
  Set<K> _newKeySet() => WeakLinkedHashSet<K>.custom(
      equals: _equals, hashCode: _hashCode, isValidKey: _validKey);
}

/// [MixedRefLinkedHashMap] 的类型别名。
typedef MixedWeakLinkedHashMap<K extends Object, V> = MixedRefLinkedHashMap<K, V>;

/// [MixedRefLinkedHashMap] 的类型别名。
typedef MixedLinkedHashMap<K extends Object, V> = MixedRefLinkedHashMap<K, V>;
