import 'dart:collection';

import 'package:meta/meta.dart';

class TypeTest<T> {
  bool test(Object? o) => o is T;
}

T unsafeCast<T>(dynamic e) => e;

bool defaultEquals(Object? a, Object? b) => a == b;

int defaultHashCode(Object? o) => o.hashCode;

final Finalizer<_FinalizationToken> _tokenFinalizer =
    Finalizer((token) => token._finalizer = null);

class _FinalizationToken<T extends Object> {
  WeakReference<T>? _token;
  void Function(T)? _finalizer;

  T? get token => _token?.target;

  void Function(T)? get finalizer => _finalizer;

  _FinalizationToken(T token, this._finalizer) : _token = WeakReference(token) {
    _tokenFinalizer.attach(token, this, detach: _token);
  }

  void _invokeFinalizer() {
    var token = _token;
    if (token != null) {
      _tokenFinalizer.detach(token);
      var t = token.target;
      if (t != null) {
        finalizer?.call(t);
        t = null;
      }
      token = null;
    }
    _finalizer = null;
  }

  void _release() {
    var token = _token;
    if (token != null) {
      _token = null;
      _tokenFinalizer.detach(token);
      token = null;
    }
    _finalizer = null;
  }
}

class _WeakEntry<E extends Object> {
  Queue<_WeakEntry<E>>? _queue;
  _FinalizationToken? _finalizationToken;

  _WeakEntry(this._queue, _FinalizationToken finalizationToken)
      : _finalizationToken = finalizationToken;

  bool _finalize() {
    var target = _finalizationToken;
    if (target != null) {
      if (target.token != null) {
        _queue?.add(this);
      }
      target._invokeFinalizer();
      target = null;
      _queue = null;
      return true;
    }
    return false;
  }

  void _release() {
    _queue = null;
    _finalizationToken?._release();
    _finalizationToken = null;
  }
}

void _finalize(_WeakEntry entry) {
  entry._finalize();
}

class WeakReferenceQueue<E extends Object, T extends Object> {
  final Finalizer<_WeakEntry<E>> _finalizer = Finalizer(_finalize);

  Queue<_WeakEntry<E>> _queue;
  final Expando<_WeakEntry<E>> _tokens = Expando();

  WeakReferenceQueue() : _queue = Queue();

  void attach(WeakReference<E> weakReference, T finalizationToken,
      {void Function(T)? finalizationCallback}) {
    var entry = _tokens[weakReference];
    if (entry != null) {
      entry._release();
      _tokens[weakReference] = null;
    }

    final target = weakReference.target;
    if (target != null) {
      final token = _WeakEntry(_queue,
          _FinalizationToken<T>(finalizationToken, finalizationCallback));
      _tokens[weakReference] = token;
      _finalizer.attach(target, token, detach: weakReference);
    }
  }

  void detach(WeakReference<E> weakReference) {
    _finalizer.detach(weakReference);
    var entry = _tokens[weakReference];
    if (entry != null) {
      _tokens[weakReference] = null;
      entry._release();
    }
  }

  void clear() => _queue = Queue();

  bool get isEmpty => _queue.isEmpty;

  bool get isNotEmpty => _queue.isNotEmpty;

  void expungeStale(void Function(T) visit) {
    if (_queue.isEmpty) return;
    final queue = _queue;
    do {
      _WeakEntry<E>? target = queue.removeFirst();
      var token = target._finalizationToken?.token;
      if (token != null) {
        visit(token as dynamic);
        token = null;
      }
      target._release();
    } while (queue.isNotEmpty);
  }
}

@visibleForTesting
extension WeakReferenceQueueTestExt<E extends Object, T extends Object>
    on WeakReferenceQueue<E, T> {
  @visibleForTesting
  Object? getWeakEntry(WeakReference<E> weakReference) =>
      _tokens[weakReference];

  @visibleForTesting
  Object? getFinalizationToken(WeakReference<E> weakReference) =>
      _tokens[weakReference]?._finalizationToken?.token;

  @visibleForTesting
  Object? getFinalizationCallback(WeakReference<E> weakReference) =>
      _tokens[weakReference]?._finalizationToken?.finalizer;
}
