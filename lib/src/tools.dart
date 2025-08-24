import 'dart:collection';

class TypeTest<T> {
  bool test(Object? o) => o is T;
}

T unsafeCast<T>(dynamic e) => e;

bool defaultEquals(Object? a, Object? b) => a == b;

int defaultHashCode(Object? o) => o.hashCode;

final Finalizer<_FinalizationToken> _tokenFinalizer =
    Finalizer((token) => token._finalizer = null);

class _FinalizationToken<T extends Object> {
  final WeakReference<T> _token;
  void Function(T)? _finalizer;

  T? get token => _token.target;

  void Function(T)? get finalizer => _finalizer;

  _FinalizationToken(T token, this._finalizer) : _token = WeakReference(token) {
    _tokenFinalizer.attach(token, this, detach: _token);
  }

  void _invokeFinalizer() {
    final token = _token.target;
    _tokenFinalizer.detach(_token);
    if (token != null) {
      finalizer?.call(token);
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
    _FinalizationToken? target = _finalizationToken;
    if (target != null) {
      target._invokeFinalizer();
      if (target.token != null) {
        _queue?.add(this);
      }
      target = null;
      _queue = null;
      return true;
    }
    return false;
  }
}

void _finalize(_WeakEntry entry) {
  entry._finalize();
}

class WeakReferenceQueue<E extends Object, T extends Object> {
  final Finalizer<_WeakEntry<E>> _finalizer = Finalizer(_finalize);

  Queue<_WeakEntry<E>> _queue;

  WeakReferenceQueue() : _queue = Queue();

  void attach(WeakReference<E> weakReference, T finalizationToken,
      {void Function(T)? finalizationCallback}) {
    final target = weakReference.target;
    if (target != null) {
      final token = _FinalizationToken(finalizationToken, finalizationCallback);
      _finalizer.attach(target, _WeakEntry(_queue, token),
          detach: weakReference);
    }
  }

  void detach(WeakReference<E> weakReference) {
    _finalizer.detach(weakReference);
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
        target._finalizationToken = null;
      }
    } while (queue.isNotEmpty);
  }
}
