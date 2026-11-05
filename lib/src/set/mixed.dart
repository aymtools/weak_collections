part of 'hash_set.dart';

/// 混杂模式 HashSet 节点 Entry。
///
/// 当 [isWeak] 为 `true` 时，借由父类的 `WeakReference` + `WeakReferenceQueue` 管理弱引用；
/// 当 [isWeak] 为 `false` 时，在 [_strongKey] 中持有强引用，且不向 Finalizer 队列注册，保证元素不被 GC 自动清理。
class _MixedHashSetEntry<E extends Object> extends _WeakHashSetEntry<E> {
  final E? _strongKey;
  final bool isWeakRef;

  _MixedHashSetEntry(
      E key,
      int hashCode,
      _WeakHashSetEntry<E>? next,
      WeakReferenceQueue<E, _WeakHashSetEntry<E>>? queue,
      bool isWeak)
      : isWeakRef = isWeak,
        _strongKey = isWeak ? null : key,
        super(
          key,
          hashCode,
          next,
          isWeak ? queue : null,
        );

  @override
  E? get value => _strongKey ?? super.value;
}

/// 混杂模式 LinkedHashSet 节点 Entry。
///
/// 继承自 [_WeakLinkedHashSetEntry]，用于在混杂引用模式下同时维护双向链表节点。
class _MixedLinkedHashSetEntry<E extends Object>
    extends _WeakLinkedHashSetEntry<E> {
  final E? _strongKey;
  final bool isWeakRef;

  _MixedLinkedHashSetEntry(
      E key,
      int hashCode,
      _WeakHashSetEntry<E>? next,
      WeakReferenceQueue<E, _WeakHashSetEntry<E>>? queue,
      bool isWeak)
      : isWeakRef = isWeak,
        _strongKey = isWeak ? null : key,
        super(
          key,
          hashCode,
          next,
          isWeak ? queue : null,
        );

  @override
  E? get value => _strongKey ?? super.value;
}

/// 混杂模式弱引用 Set Mixin。
///
/// 混杂模式允许向 Set 中添加元素时显式或隐式地指定为**弱引用**还是**强引用**。
mixin MixedRefHashSetMixin<E extends Object> on WeakHashSetMixin<E> {
  /// 构造函数中传入的引用类型决策谓词，若为 `null` 则默认采用弱引用。
  bool Function(E)? get _isWeakPredicate => null;

  /// 解析指定元素 [element] 的引用模式。
  ///
  /// 优先使用显式传入的 [isWeak]，若未传入则回退至 [_isWeakPredicate] 谓词，默认返回 `true`（弱引用）。
  bool _resolveIsWeak(E element, bool? isWeak) {
    if (isWeak != null) return isWeak;
    final predicate = _isWeakPredicate;
    if (predicate != null) return predicate(element);
    return true;
  }

  /// 向 Set 中添加元素 [value]，允许显式指定 [isWeak] 控制强弱引用模式。
  ///
  /// - [isWeak] 为 `true` 时，以**弱引用**形式保存该元素（GC 后自动清除）。
  /// - [isWeak] 为 `false` 时，以**强引用**形式保存该元素（常驻内存，直到手动调用 [remove]）。
  /// - [isWeak] 为 `null` 时，使用默认引用策略（构造时传入的 [_isWeakPredicate] 或默认弱引用）。
  /// - 如果元素已存在但当前的引用模式与目标 [isWeak] 不一致，会自动升级/转换为目标的引用模式并返回 `true`。
  @override
  bool add(E value, {bool? isWeak}) {
    _expungeStaleEntries();
    return _addWithRef(value, isWeak: isWeak);
  }

  /// 以**弱引用**形式添加元素 [value]。
  bool addWeak(E value) => add(value, isWeak: true);

  /// 以**强引用**形式添加元素 [value]。
  bool addStrong(E value) => add(value, isWeak: false);

  /// 内部带引用模式处理的元素添加实现。
  bool _addWithRef(E value, {bool? isWeak}) {
    final hashCode = _hashCode(value);
    final index = hashCode & (_buckets.length - 1);
    var entry = _buckets[index];
    _WeakHashSetEntry<E>? previous;

    final targetIsWeak = _resolveIsWeak(value, isWeak);

    while (entry != null) {
      if (_equals(entry.value, value)) {
        if (entry is _MixedHashSetEntry<E>) {
          if (entry.isWeakRef != targetIsWeak) {
            // 元素已存在但引用模式不同，替换节点以升级/转换引用模式
            final newEntry = _makeMixedEntry(
                value, hashCode, entry.next, _queue, targetIsWeak);
            if (previous == null) {
              _buckets[index] = newEntry;
            } else {
              previous.next = newEntry;
            }
            entry.remove();
            return true;
          }
        }
        return false;
      }
      previous = entry;
      entry = entry.next;
    }

    final newEntry =
        _makeMixedEntry(value, hashCode, _buckets[index], _queue, targetIsWeak);
    _addEntry(index, newEntry);
    return true;
  }

  /// 创建带强弱引用标志的混杂 Entry 节点。
  _WeakHashSetEntry<E> _makeMixedEntry(
      E value,
      int hashCode,
      _WeakHashSetEntry<E>? next,
      WeakReferenceQueue<E, _WeakHashSetEntry<E>> queue,
      bool isWeak) {
    return _MixedHashSetEntry<E>(
        value, hashCode, next, queue, isWeak);
  }

  /// 模板方法：在底层被 [WeakHashSetMixin] 的内部逻辑或 Dart 标准 `Set` 接口（如 `addAll`、`Set.from` 等）调用。
  ///
  /// **注意点**：此处**绝不能直接抛出异常**！
  /// 因为 Dart 标准 `Set` 接口的方法（如 `set.add(element)`、`set.addAll(...)`、`Set.from(...)` 等）
  /// 在底层均依赖 `_makeEntry` 构建节点。
  /// 此处通过 `_resolveIsWeak(value, null)` 降级使用默认策略（弱引用或谓词控制）生成混杂节点，
  /// 既保证了兼容 Dart 标准 `Set` API，又不会破坏混杂模式功能。
  @override
  _WeakHashSetEntry<E> _makeEntry(
          E value,
          int hashCode,
          _WeakHashSetEntry<E>? next,
          WeakReferenceQueue<E, _WeakHashSetEntry<E>> queue) =>
      _makeMixedEntry(value, hashCode, next, queue, _resolveIsWeak(value, null));

  @override
  void _removeEntry(_WeakHashSetEntry<E> entry,
      _WeakHashSetEntry<E>? previousInBucket, int bucketIndex) {
    if (previousInBucket == null) {
      _buckets[bucketIndex] = entry.remove();
    } else {
      previousInBucket.next = entry.remove();
    }
  }
}

/// 混杂模式弱引用 HashSet 实现类。
///
/// 允许按需指定弱引用或强引用保存元素，兼具 `WeakHashSet` 和标准 `HashSet` 的特性。
class MixedRefHashSet<E extends Object> extends WeakHashSet<E>
    with MixedRefHashSetMixin<E> {
  @override
  final bool Function(E)? _isWeakPredicate;

  /// 构造一个 [MixedRefHashSet]，可选传入 [isWeak] 决策谓词。
  MixedRefHashSet({bool Function(E)? isWeak}) : _isWeakPredicate = isWeak;

  /// 构造一个使用 Identity（`identical` 与 `identityHashCode`）比较的 [MixedRefHashSet]。
  factory MixedRefHashSet.identity({bool Function(E)? isWeak}) =>
      _IdentityMixedRefHashSet<E>(isWeak: isWeak);

  /// 从已有集合 [elements] 创建 [MixedRefHashSet]。
  factory MixedRefHashSet.from(Iterable<dynamic> elements,
      {bool Function(E)? isWeak}) {
    MixedRefHashSet<E> result = MixedRefHashSet<E>(isWeak: isWeak);
    for (final element in elements) {
      result.add(element as E);
    }
    return result;
  }

  /// 从已有 Iterable [elements] 创建 [MixedRefHashSet]。
  factory MixedRefHashSet.of(Iterable<E> elements, {bool Function(E)? isWeak}) =>
      MixedRefHashSet<E>(isWeak: isWeak)..addAll(elements);

  /// 构造一个带有自定义 [equals]、[hashCode]、[isValidKey] 与 [isWeak] 的 [MixedRefHashSet]。
  factory MixedRefHashSet.custom({
    bool Function(E, E)? equals,
    int Function(E)? hashCode,
    bool Function(Object?)? isValidKey,
    bool Function(E)? isWeak,
  }) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return MixedRefHashSet<E>(isWeak: isWeak);
        }
        hashCode = defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return _IdentityMixedRefHashSet<E>(isWeak: isWeak);
        }
        equals ??= defaultEquals;
      }
    } else {
      hashCode ??= defaultHashCode;
      equals ??= defaultEquals;
    }
    return _CustomMixedRefHashSet<E>(equals, hashCode, isValidKey, isWeak);
  }

  @override
  Set<E> _newSet() => MixedRefHashSet<E>(isWeak: _isWeakPredicate);
}

class _IdentityMixedRefHashSet<E extends Object> extends MixedRefHashSet<E>
    with _IdentityWeakHashSetMixin<E> {
  _IdentityMixedRefHashSet({super.isWeak});

  @override
  Set<E> _newSet() => _IdentityMixedRefHashSet<E>(isWeak: _isWeakPredicate);
}

class _CustomMixedRefHashSet<E extends Object> extends MixedRefHashSet<E>
    with _CustomWeakHashSetMixin<E> {
  @override
  final bool Function(E, E) _equality;
  @override
  final int Function(E) _hasher;
  @override
  final bool Function(Object?) _validKey;

  _CustomMixedRefHashSet(
      this._equality, this._hasher, bool Function(Object?)? validKey,
      [bool Function(E)? isWeak])
      : _validKey = (validKey != null) ? validKey : TypeTest<E>().test,
        super(isWeak: isWeak);

  @override
  Set<E> _newSet() => _CustomMixedRefHashSet<E>(
      _equality, _hasher, _validKey, _isWeakPredicate);
}

/// [MixedRefHashSet] 的类型别名。
typedef MixedWeakHashSet<E extends Object> = MixedRefHashSet<E>;

/// [MixedRefHashSet] 的类型别名。
typedef MixedHashSet<E extends Object> = MixedRefHashSet<E>;

/// 混杂模式弱引用 LinkedHashSet 实现类。
///
/// 在混杂引用的基础上保留元素的插入顺序。
class MixedRefLinkedHashSet<E extends Object> extends WeakLinkedHashSet<E>
    with MixedRefHashSetMixin<E> {
  @override
  final bool Function(E)? _isWeakPredicate;

  /// 构造一个 [MixedRefLinkedHashSet]，可选传入 [isWeak] 决策谓词。
  MixedRefLinkedHashSet({bool Function(E)? isWeak}) : _isWeakPredicate = isWeak;

  /// 构造一个使用 Identity 比较的 [MixedRefLinkedHashSet]。
  factory MixedRefLinkedHashSet.identity({bool Function(E)? isWeak}) =>
      _IdentityMixedRefLinkedHashSet<E>(isWeak: isWeak);

  /// 从已有集合 [elements] 创建 [MixedRefLinkedHashSet]。
  factory MixedRefLinkedHashSet.from(Iterable<dynamic> elements,
      {bool Function(E)? isWeak}) {
    MixedRefLinkedHashSet<E> result =
        MixedRefLinkedHashSet<E>(isWeak: isWeak);
    for (final element in elements) {
      result.add(element as E);
    }
    return result;
  }

  /// 从已有 Iterable [elements] 创建 [MixedRefLinkedHashSet]。
  factory MixedRefLinkedHashSet.of(Iterable<E> elements,
          {bool Function(E)? isWeak}) =>
      MixedRefLinkedHashSet<E>(isWeak: isWeak)..addAll(elements);

  /// 构造一个带有自定义比较器的 [MixedRefLinkedHashSet]。
  factory MixedRefLinkedHashSet.custom({
    bool Function(E, E)? equals,
    int Function(E)? hashCode,
    bool Function(Object?)? isValidKey,
    bool Function(E)? isWeak,
  }) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return MixedRefLinkedHashSet<E>(isWeak: isWeak);
        }
        hashCode = defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return _IdentityMixedRefLinkedHashSet<E>(isWeak: isWeak);
        }
        equals ??= defaultEquals;
      }
    } else {
      hashCode ??= defaultHashCode;
      equals ??= defaultEquals;
    }
    return _CustomMixedRefLinkedHashSet<E>(
        equals, hashCode, isValidKey, isWeak);
  }

  @override
  _WeakHashSetEntry<E> _makeMixedEntry(
      E value,
      int hashCode,
      _WeakHashSetEntry<E>? next,
      WeakReferenceQueue<E, _WeakHashSetEntry<E>> queue,
      bool isWeak) {
    final entry = _MixedLinkedHashSetEntry<E>(
        value, hashCode, next, queue, isWeak);
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
  Set<E> _newSet() => MixedRefLinkedHashSet<E>(isWeak: _isWeakPredicate);
}

class _IdentityMixedRefLinkedHashSet<E extends Object>
    extends MixedRefLinkedHashSet<E> with _IdentityWeakHashSetMixin<E> {
  _IdentityMixedRefLinkedHashSet({super.isWeak});

  @override
  Set<E> _newSet() =>
      _IdentityMixedRefLinkedHashSet<E>(isWeak: _isWeakPredicate);
}

class _CustomMixedRefLinkedHashSet<E extends Object>
    extends MixedRefLinkedHashSet<E> with _CustomWeakHashSetMixin<E> {
  @override
  final bool Function(E, E) _equality;
  @override
  final int Function(E) _hasher;
  @override
  final bool Function(Object?) _validKey;

  _CustomMixedRefLinkedHashSet(
      this._equality, this._hasher, bool Function(Object?)? validKey,
      [bool Function(E)? isWeak])
      : _validKey = (validKey != null) ? validKey : TypeTest<E>().test,
        super(isWeak: isWeak);

  @override
  Set<E> _newSet() => _CustomMixedRefLinkedHashSet<E>(
      _equality, _hasher, _validKey, _isWeakPredicate);
}

/// [MixedRefLinkedHashSet] 的类型别名。
typedef MixedWeakLinkedHashSet<E extends Object> = MixedRefLinkedHashSet<E>;

/// [MixedRefLinkedHashSet] 的类型别名。
typedef MixedLinkedHashSet<E extends Object> = MixedRefLinkedHashSet<E>;
