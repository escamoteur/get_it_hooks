import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get_it/get_it.dart';

AsyncSnapshot<R> useWatchStream<T, R>(
    Stream<R> Function(T) select, R initialValue,
    {String instanceName, bool preserveState = true}) {
  assert(select != null, 'select can not be null in useWatchStream');
  return use(_WatchStreamHook<T, R>(
      select: select,
      instanceName: instanceName,
      initialValue: initialValue,
      preserveState: preserveState));
}

class _WatchStreamHook<T, R> extends Hook<AsyncSnapshot<R>> {
  const _WatchStreamHook(
      {@required this.instanceName,
      @required this.select,
      @required this.initialValue,
      @required this.preserveState,
      this.handler});

  final void Function(BuildContext context, AsyncSnapshot<R> snapshot,
      void Function() cancel) handler;
  final bool preserveState;
  final R initialValue;
  final String instanceName;
  final Stream<R> Function(T) select;
  @override
  _WatchStreamHookState<T, R> createState() => _WatchStreamHookState<T, R>();
}

class _WatchStreamHookState<T, R>
    extends HookState<AsyncSnapshot<R>, _WatchStreamHook<T, R>> {
  Stream<R> stream;
  StreamSubscription<R> _subscription;
  T targetObject;
  AsyncSnapshot<R> _lastValue;

  @override
  void initHook() {
    super.initHook();
    targetObject = GetIt.I<T>(instanceName: hook.instanceName);
    stream = hook.select(targetObject);
    assert(stream != null, 'select returned null in useWatchStream');

    _lastValue = initial();
    if (hook.handler != null && hook.initialValue != null) {
      hook.handler(this.context, _lastValue, _unsubscribe);
    }
    _subscribe();
  }

  @override
  AsyncSnapshot<R> build(BuildContext context) {
    return _lastValue;
  }

  @override
  void didUpdateHook(_WatchStreamHook<T, R> oldHook) {
    super.didUpdateHook(oldHook);
    if (oldHook.instanceName != hook.instanceName ||
        oldHook.select(targetObject) != stream) {
      if (_subscription != null) {
        _unsubscribe();
        if (hook.preserveState) {
          _lastValue = afterDisconnected(_lastValue);
        } else {
          _lastValue = initial();
          if (hook.handler != null && hook.initialValue != null) {
            hook.handler(this.context, _lastValue, _unsubscribe);
          }
        }
      }
      targetObject = GetIt.I<T>(instanceName: hook.instanceName);
      stream = hook.select(targetObject);
      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _subscribe() {
    if (stream != null) {
      _subscription = stream.listen((data) {
        setState(() {
          _lastValue = afterData(_lastValue, data);
        });

        hook.handler?.call(this.context, _lastValue, _unsubscribe);
      }, onError: (dynamic error) {
        setState(() {
          _lastValue = afterError(_lastValue, error);
        });
        hook.handler?.call(this.context, _lastValue, _unsubscribe);
      }, onDone: () {
        setState(() {
          _lastValue = afterDone(_lastValue);
        });
        hook.handler?.call(this.context, _lastValue, _unsubscribe);
      });
      _lastValue = afterConnected(_lastValue);
    }
  }

  AsyncSnapshot<R> initial() =>
      AsyncSnapshot<R>.withData(ConnectionState.none, hook.initialValue);

  AsyncSnapshot<R> afterConnected(AsyncSnapshot<R> current) =>
      current.inState(ConnectionState.waiting);

  AsyncSnapshot<R> afterData(AsyncSnapshot<R> current, R data) {
    return AsyncSnapshot<R>.withData(ConnectionState.active, data);
  }

  AsyncSnapshot<R> afterError(AsyncSnapshot<R> current, Object error) {
    return AsyncSnapshot<R>.withError(ConnectionState.active, error);
  }

  AsyncSnapshot<R> afterDone(AsyncSnapshot<R> current) =>
      current.inState(ConnectionState.done);

  AsyncSnapshot<R> afterDisconnected(AsyncSnapshot<R> current) =>
      current.inState(ConnectionState.none);

  @override
  String get debugLabel => 'useWatchStream';
}

AsyncSnapshot<R> useWatchFuture<T, R>(
    Future<R> Function(T) select, R initialValue,
    {String instanceName, bool preserveState = true}) {
  assert(select != null, 'select can not be null in useWatchStream');
  return use(_WatchFutureHook<T, R>(
    select: select,
    instanceName: instanceName,
    initialValueProvider: () => initialValue,
    preserveState: preserveState,
  ));
}

class _WatchFutureHook<T, R> extends Hook<AsyncSnapshot<R>> {
  const _WatchFutureHook({
    @required this.instanceName,
    @required this.select,
    @required this.preserveState,
    this.handler,
    this.futureProvider,
    this.initialValueProvider,
    this.executeImmediately = false,
  });
  final bool executeImmediately;
  final Future<R> Function() futureProvider;
  final R Function() initialValueProvider;
  final void Function(BuildContext context, AsyncSnapshot<R> snapshot,
      void Function() cancel) handler;
  final bool preserveState;
  final String instanceName;
  final Future<R> Function(T) select;
  @override
  _WatchFutureHookState<T, R> createState() => _WatchFutureHookState<T, R>();
}

class _WatchFutureHookState<T, R>
    extends HookState<AsyncSnapshot<R>, _WatchFutureHook<T, R>> {
  Future<R> future;
  T targetObject;
  AsyncSnapshot<R> _lastValue;

  Object _activeCallbackIdentity;

  @override
  void initHook() {
    super.initHook();
    if (hook.futureProvider == null) {
      targetObject = GetIt.I<T>(instanceName: hook.instanceName);
      future = hook.select(targetObject);
      assert(future != null, 'select returned null in useWatchFuture');
    } else {
      future = hook.futureProvider();
    }
    _lastValue = AsyncSnapshot.withData(
        ConnectionState.none, hook.initialValueProvider?.call());

    if (hook.handler != null && hook.executeImmediately) {
      hook.handler(this.context, _lastValue, _unsubscribe);
    }
    _subscribe();
  }

  void _subscribe() {
    if (future != null) {
      /// by using a local variable we ensure that only the value and not the
      /// variable is captured.
      final callbackIdentity = Object();
      _activeCallbackIdentity = callbackIdentity;
      future.then(
        (x) {
          if (_activeCallbackIdentity == callbackIdentity) {
            // only update if Future is still valid
            setState(() =>
                _lastValue = AsyncSnapshot.withData(ConnectionState.done, x));
            hook.handler?.call(this.context, _lastValue, _unsubscribe);
          }
        },
        onError: (error) {
          if (future != null) {
            // print('Future error');
            setState(() => _lastValue =
                AsyncSnapshot.withError(ConnectionState.done, error));
            hook.handler?.call(this.context, _lastValue, _unsubscribe);
          }
        },
      );
      _lastValue = _lastValue.inState(ConnectionState.waiting);
    }
  }

  void _unsubscribe() {
    _activeCallbackIdentity = null;
  }

  @override
  AsyncSnapshot<R> build(BuildContext context) {
    return _lastValue;
  }

  @override
  void didUpdateHook(_WatchFutureHook<T, R> oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.futureProvider == null &&
        (oldHook.instanceName != hook.instanceName ||
            oldHook.select(targetObject) != future)) {
      if (_activeCallbackIdentity != null) {
        _unsubscribe();
        if (!hook.preserveState) {
          _lastValue = AsyncSnapshot.withData(
              ConnectionState.none, hook.initialValueProvider?.call());
        } else {
          _lastValue = _lastValue.inState(ConnectionState.none);
          if (hook.handler != null && hook.executeImmediately) {
            hook.handler(this.context, _lastValue, _unsubscribe);
          }
        }
      }
      targetObject = GetIt.I<T>(instanceName: hook.instanceName);
      future = hook.select(targetObject);

      _subscribe();
    }
  }

  @override
  void dispose() {
    _unsubscribe();
  }

  @override
  String get debugLabel => 'useWatchFuture';
}

void useStreamHandler<T, R>(
    Stream<R> Function(T) select,
    void Function(BuildContext context, AsyncSnapshot<R> newValue,
            void Function() cancel)
        handler,
    {R initialValue,
    String instanceName,
    bool preserveState = true}) {
  return use(_WatchStreamHook<T, R>(
    initialValue: initialValue,
    select: select,
    handler: handler,
    instanceName: instanceName,
    preserveState: preserveState,
  ));
}

void useFutureHandler<T, R>(
    Future<R> Function(T) select,
    void Function(BuildContext context, AsyncSnapshot<R> newValue,
            void Function() cancel)
        handler,
    {R initialValue,
    String instanceName,
    bool preserveState = true,
    bool executeImmediately = false}) {
  return use(_WatchFutureHook<T, R>(
      initialValueProvider: () => initialValue,
      select: select,
      handler: handler,
      instanceName: instanceName,
      preserveState: preserveState,
      executeImmediately: executeImmediately));
}

bool useAllReady(
    {void Function(BuildContext context) onReady,
    void Function(BuildContext context, Object error) onError,
    Duration timeout}) {
  return use(_WatchFutureHook<void, bool>(
    instanceName: null,
    select: null,
    preserveState: true,
    handler: (context, x, dispose) {
      if (x.hasError) {
        onError?.call(context, x.error);
      } else {
        onReady?.call(context);
        (context as Element).markNeedsBuild();
      }
      dispose();
    },
    initialValueProvider: () => GetIt.I.allReadySync(),

    /// as `GetIt.allReady` returns a Future<void> we convert it
    /// to a bool because if this Future completes the meaning is true.
    futureProvider: () => GetIt.I.allReady(timeout: timeout).then((_) => true),
  )).data;
}

bool useIsReady<T>(
    {void Function(BuildContext context) onReady,
    void Function(BuildContext context, Object error) onError,
    Duration timeout,
    String instanceName}) {
  return use(_WatchFutureHook<void, bool>(
      preserveState: true,
      select: null,
      instanceName: instanceName,
      handler: (context, x, cancel) {
        if (x.hasError) {
          onError?.call(context, x.error);
        } else {
          onReady?.call(context);
        }
        (context as Element).markNeedsBuild();
        cancel(); // we want exactly one call.
      },
      initialValueProvider: () =>
          GetIt.I.isReadySync<T>(instanceName: instanceName),

      /// as `GetIt.allReady` returns a Future<void> we convert it
      /// to a bool because if this Future completes the meaning is true.
      futureProvider: () => GetIt.I
          .isReady<T>(instanceName: instanceName, timeout: timeout)
          .then((_) => true))).data;
}
