import 'dart:collection';

import 'package:meta/meta.dart';
import 'package:weak_collections/src/tools.dart';

part 'base.dart';
part 'linked_hash_set.dart';

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
    _current = null;
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
    return false;
  }

  @override
  E get current => _current as E;
}

class WeakHashSet<E extends Object> extends SetMixin<E>
    with WeakHashSetMixin<E> {
  WeakHashSet();

  factory WeakHashSet.identity() => _IdentityWeakHashSet<E>();

  factory WeakHashSet.from(Iterable<dynamic> elements) {
    WeakHashSet<E> result = WeakHashSet<E>();
    for (final element in elements) {
      result.add(element as E);
    }
    return result;
  }

  factory WeakHashSet.of(Iterable<E> elements) =>
      WeakHashSet<E>()..addAll(elements);

  factory WeakHashSet.custom(
      {bool Function(E, E)? equals,
      int Function(E)? hashCode,
      bool Function(Object?)? isValidKey}) {
    if (isValidKey == null) {
      if (hashCode == null) {
        if (equals == null) {
          return WeakHashSet<E>();
        }
        hashCode = defaultHashCode;
      } else {
        if (identical(identityHashCode, hashCode) &&
            identical(identical, equals)) {
          return _IdentityWeakHashSet<E>();
        }
        equals ??= defaultEquals;
      }
    } else {
      hashCode ??= defaultHashCode;
      equals ??= defaultEquals;
    }
    return _CustomWeakHashSet<E>(equals, hashCode, isValidKey);
  }

  // Iterable.
  @override
  Iterator<E> get iterator {
    _expungeStaleEntries();
    return _WeakHashSetIterator<E>(this);
  }

  @override
  Set<E> _newSet() => WeakHashSet();
}

class _IdentityWeakHashSet<E extends Object> extends WeakHashSet<E>
    with _IdentityWeakHashSetMixin<E> {
  @override
  WeakHashSet<E> _newSet() => _IdentityWeakHashSet<E>();
}

class _CustomWeakHashSet<E extends Object> extends WeakHashSet<E>
    with _CustomWeakHashSetMixin<E> {
  @override
  final bool Function(E, E) _equality;
  @override
  final int Function(E) _hasher;
  @override
  final bool Function(Object?) _validKey;

  _CustomWeakHashSet(
      this._equality, this._hasher, bool Function(Object?)? validKey)
      : _validKey = (validKey != null) ? validKey : TypeTest<E>().test;

  @override
  WeakHashSet<E> _newSet() =>
      _CustomWeakHashSet<E>(_equality, _hasher, _validKey);
}
