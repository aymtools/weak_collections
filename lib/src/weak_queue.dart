import 'dart:collection';

class WeakQueue<T extends Object> with Iterable<T> implements Queue<T> {
  final Queue<_WeakRef<T>> _refs = Queue<_WeakRef<T>>();
  final Finalizer<_WeakRef<T>> _finalizer = Finalizer((ref) {
    ref._isCollected = true;
  });

  @override
  void add(T value) {
    final ref = _WeakRef(value);
    _refs.add(ref);
    _finalizer.attach(value, ref, detach: ref);
  }

  @override
  void addAll(Iterable<T> values) {
    for (final v in values) {
      add(v);
    }
  }

  @override
  void addFirst(T value) {
    final ref = _WeakRef(value);
    _refs.addFirst(ref);
    _finalizer.attach(value, ref, detach: ref);
  }

  @override
  void addLast(T value) {
    final ref = _WeakRef(value);
    _refs.addLast(ref);
    _finalizer.attach(value, ref, detach: ref);
  }

  @override
  T removeFirst() {
    _expungeStaleEntries();
    while (_refs.isNotEmpty) {
      final ref = _refs.removeFirst();
      final target = ref._value.target;
      if (!ref._isCollected && target != null) {
        _finalizer.detach(ref);
        return target;
      }
    }
    throw StateError('No element');
  }

  @override
  T removeLast() {
    _expungeStaleEntries();
    while (_refs.isNotEmpty) {
      final ref = _refs.removeLast();
      final target = ref._value.target;
      if (!ref._isCollected && target != null) {
        _finalizer.detach(ref);
        return target;
      }
    }
    throw StateError('No element');
  }

  @override
  bool get isEmpty {
    _expungeStaleEntries();
    return _refs.isEmpty;
  }

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  int get length {
    _expungeStaleEntries();
    return _refs.length;
  }

  @override
  Iterator<T> get iterator => _WeakQueueIterator(_refs);

  @override
  void clear() {
    for (final ref in _refs) {
      _finalizer.detach(ref);
    }
    _refs.clear();
  }

  void _expungeStaleEntries() {
    _refs.removeWhere((ref) => ref._isCollected || ref._value.target == null);
  }

  @override
  bool remove(Object? value) {
    _expungeStaleEntries();
    for (final ref in _refs) {
      if (!ref._isCollected && ref._value.target == value) {
        _finalizer.detach(ref);
        _refs.remove(ref);
        return true;
      }
    }
    return false;
  }

  @override
  void removeWhere(bool Function(T element) test) {
    _expungeStaleEntries();
    final toRemove = <_WeakRef<T>>[];

    for (final ref in _refs) {
      final target = ref._value.target;
      if (!ref._isCollected && target != null && test(target)) {
        toRemove.add(ref);
      }
    }

    for (final ref in toRemove) {
      _finalizer.detach(ref);
      _refs.remove(ref);
    }
  }

  @override
  void retainWhere(bool Function(T element) test) {
    _expungeStaleEntries();
    final toRemove = <_WeakRef<T>>[];
    for (final ref in _refs) {
      final target = ref._value.target;
      if (!ref._isCollected && target != null && !test(target)) {
        toRemove.add(ref);
      }
    }

    for (final ref in toRemove) {
      _finalizer.detach(ref);
      _refs.remove(ref);
    }
  }

  @override
  Queue<R> cast<R>() => _WeakQueueCastView<T, R>(this);
}

class _WeakRef<T extends Object> {
  final WeakReference<T> _value;
  bool _isCollected = false;

  _WeakRef(T value) : _value = WeakReference(value);
}

class _WeakQueueIterator<T extends Object> extends Iterator<T> {
  final Iterator<_WeakRef<T>> _refIterator;
  T? _current;

  _WeakQueueIterator(Iterable<_WeakRef<T>> refs) : _refIterator = refs.iterator;

  @override
  T get current => _current as T;

  @override
  bool moveNext() {
    while (_refIterator.moveNext()) {
      final ref = _refIterator.current;
      final target = ref._value.target;
      if (!ref._isCollected && target != null) {
        _current = target;
        return true;
      }
    }
    _current = null;
    return false;
  }
}

class _WeakQueueCastView<S extends Object, R>
    with Iterable<R>
    implements Queue<R> {
  final WeakQueue<S> _source;

  _WeakQueueCastView(this._source);

  @override
  void add(R value) {
    _source.add(value as S);
  }

  @override
  void addAll(Iterable<R> iterable) {
    _source.addAll(iterable.cast<S>());
  }

  @override
  R removeFirst() => _source.removeFirst() as R;

  @override
  R removeLast() => _source.removeLast() as R;

  @override
  bool remove(Object? value) => _source.remove(value);

  @override
  void clear() => _source.clear();

  @override
  int get length => _source.length;

  @override
  bool get isEmpty => _source.isEmpty;

  @override
  bool get isNotEmpty => _source.isNotEmpty;

  @override
  Iterator<R> get iterator => _source.map((e) => e as R).iterator;

  @override
  R elementAt(int index) => _source.elementAt(index) as R;

  @override
  void addFirst(R value) => _source.addFirst(value as S);

  @override
  void addLast(R value) => _source.addLast(value as S);

  @override
  void removeWhere(bool Function(R element) test) =>
      _source.removeWhere((e) => test(e as R));

  @override
  void retainWhere(bool Function(R element) test) =>
      _source.retainWhere((e) => test(e as R));

  @override
  Queue<E> cast<E>() {
    return _WeakQueueCastView<S, E>(_source);
  }
}
