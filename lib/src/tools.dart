import 'dart:collection';

import 'package:meta/meta.dart';

class TypeTest<T> {
  bool test(Object? o) => o is T;
}

T unsafeCast<T>(dynamic e) => e;

bool defaultEquals(Object? a, Object? b) => a == b;

int defaultHashCode(Object? o) => o.hashCode;

class _WeakEntry<E extends Object, T extends Object> {
  Queue<_WeakEntry<E, T>>? _queue;

  Finalizer<_WeakEntry<E, T>>? _tokenFinalizer;
  WeakReference<T>? _token;

  void Function(T)? _finalizationCallback;

  T? get token => _token?.target;

  void Function(T)? get finalizationCallback => _finalizationCallback;

  _WeakEntry(
      this._queue, this._tokenFinalizer, T token, this._finalizationCallback)
      : _token = WeakReference(token) {
    _tokenFinalizer?.attach(token, this, detach: _token);
  }

  bool _finalize() {
    bool r = false;
    var tokenW = _token;
    if (tokenW != null) {
      _tokenFinalizer?.detach(tokenW);
      final token = tokenW.target;
      if (token != null) {
        _queue?.add(this);
        finalizationCallback?.call(token);
        r = true;
      }
      _tokenFinalizer = null;
      _finalizationCallback = null;
      _queue = null;
    }
    return r;
  }

  void _release() {
    _queue = null;
    final tokenW = _token;
    if (tokenW != null) {
      _token = null;
      _tokenFinalizer?.detach(tokenW);
    }
    _tokenFinalizer = null;
    _finalizationCallback = null;
  }
}

class WeakReferenceQueue<E extends Object, T extends Object> {
  final Expando<_WeakEntry<E, T>> _tokens = Expando();

  Queue<_WeakEntry<E, T>> _queue;

  Finalizer<_WeakEntry<E, T>> _entryFinalizer;

  Finalizer<_WeakEntry<E, T>> _tokenFinalizer;

  WeakReferenceQueue()
      : _queue = Queue(),
        _entryFinalizer = Finalizer(_finalizeEntry),
        _tokenFinalizer = Finalizer(_finalizeToken);

  static void _finalizeEntry(_WeakEntry entry) {
    entry._finalize();
  }

  static void _finalizeToken(_WeakEntry entry) {
    entry._token = null;
    entry._finalizationCallback = null;
    entry._tokenFinalizer = null;
  }

  void attach(WeakReference<E> weakReference, T finalizationToken,
      {void Function(T)? finalizationCallback}) {
    var entry = _tokens[weakReference];
    if (entry != null) {
      entry._release();
      _tokens[weakReference] = null;
    }

    final target = weakReference.target;
    if (target != null) {
      final token = _WeakEntry<E, T>(
          _queue, _tokenFinalizer, finalizationToken, finalizationCallback);
      _tokens[weakReference] = token;
      _entryFinalizer.attach(target, token, detach: weakReference);
    }
  }

  void detach(WeakReference<E> weakReference) {
    _entryFinalizer.detach(weakReference);
    var entry = _tokens[weakReference];
    if (entry != null) {
      _tokens[weakReference] = null;
      entry._release();
    }
  }

  void clear() {
    _queue = Queue();
    _entryFinalizer = Finalizer(_finalizeEntry);
    _tokenFinalizer = Finalizer(_finalizeToken);
  }

  bool get isEmpty => _queue.isEmpty;

  bool get isNotEmpty => _queue.isNotEmpty;

  void expungeStale(void Function(T) visit) {
    final queue = _queue;
    while (queue.isNotEmpty) {
      var target = queue.removeFirst();
      var token = target.token;
      if (token != null) {
        visit(token as dynamic);
        token = null;
      }
      target._release();
    }
  }
}

class WeakLinkedNode<E extends Object> {
  final E value;
  WeakLinkedNode<E>? next;
  WeakLinkedNode<E>? prev;

  WeakLinkedNode(this.value);
}

@visibleForTesting
extension WeakReferenceQueueTestExt<E extends Object, T extends Object>
    on WeakReferenceQueue<E, T> {
  @visibleForTesting
  Object? getWeakEntry(WeakReference<E> weakReference) =>
      _tokens[weakReference];

  @visibleForTesting
  Object? getFinalizationToken(WeakReference<E> weakReference) =>
      _tokens[weakReference]?.token;

  @visibleForTesting
  Object? getFinalizationCallback(WeakReference<E> weakReference) =>
      _tokens[weakReference]?.finalizationCallback;
}
