import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get_it/get_it.dart';

AsyncSnapshot<R> useWatchStream<T extends Object, R>(
    Stream<R> Function(T) select, R initialValue,
    {String? instanceName, bool preserveState = true}) {
  return use(_WatchStreamHook<T, R>(
      select: select,
      instanceName: instanceName,
      initialValue: initialValue,
      preserveState: preserveState));
}

class _WatchStreamHook<T extends Object, R> extends Hook<AsyncSnapshot<R>> {
  const _WatchStreamHook(
      {required this.instanceName,
      required this.select,
      required this.initialValue,
      required this.preserveState,
      this.handler});

  final void Function(BuildContext context, AsyncSnapshot<R> snapshot,
      void Function() cancel)? handler;
  final bool preserveState;
  final R initialValue;
  final String? instanceName;
  final Stream<R> Function(T) select;
  @override
  _WatchStreamHookState<T, R> createState() => _WatchStreamHookState<T, R>();
}

class _WatchStreamHookState<T extends Object, R>
    extends HookState<AsyncSnapshot<R>, _WatchStreamHook<T, R>> {
  late Stream<R> stream;
  StreamSubscription<R>? _subscription;
  late T targetObject;
  late AsyncSnapshot<R> _lastValue;

  @override
  void initHook() {
    super.initHook();
    targetObject = GetIt.I<T>(instanceName: hook.instanceName);
    stream = hook.select(targetObject);

    _lastValue = initial();
    if (hook.handler != null && hook.initialValue != null) {
      hook.handler!(this.context, _lastValue, _unsubscribe);
    }
    _subscribe();
  }

  @override
  AsyncSnapshot<R> build(BuildContext context) {
    /// as the select could return a different Stream on different Builds
    /// we have to handle this appropriately
    final Stream<R> selectedStream = hook.select(targetObject);
    if (selectedStream != stream) {
      _switchSubscription();
    }
    return _lastValue;
  }

  @override
  void didUpdateHook(_WatchStreamHook<T, R> oldHook) {
    super.didUpdateHook(oldHook);
    if (oldHook.instanceName != hook.instanceName ||
        oldHook.select(targetObject) != stream) {
      _switchSubscription();
    }
  }

  void _switchSubscription() {
    if (_subscription != null) {
      _unsubscribe();
      if (hook.preserveState) {
        _lastValue = afterDisconnected(_lastValue);
      } else {
        _lastValue = initial();
        if (hook.handler != null && hook.initialValue != null) {
          hook.handler!(this.context, _lastValue, _unsubscribe);
        }
      }
    }
    targetObject = GetIt.I<T>(instanceName: hook.instanceName);
    stream = hook.select(targetObject);
    _subscribe();
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
    _subscription = stream.listen((data) {
      _lastValue = afterData(_lastValue, data);
      if (hook.handler == null) {
        setState(() {});
      } else {
        hook.handler?.call(this.context, _lastValue, _unsubscribe);
      }
    }, onError: (dynamic error) {
      _lastValue = afterError(_lastValue, error);
      if (hook.handler == null) {
        setState(() {});
      } else {
        hook.handler?.call(this.context, _lastValue, _unsubscribe);
      }
    }, onDone: () {
      _lastValue = afterDone(_lastValue);
      if (hook.handler == null) {
        setState(() {});
      } else {
        hook.handler?.call(this.context, _lastValue, _unsubscribe);
      }
    });
    _lastValue = afterConnected(_lastValue);
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

AsyncSnapshot<R> useWatchFuture<T extends Object, R>(
    Future<R> Function(T) select, R initialValue,
    {String? instanceName, bool preserveState = true}) {
  return use(_WatchFutureHook<T, R>(
    select: select,
    instanceName: instanceName,
    initialValueProvider: () => initialValue,
    preserveState: preserveState,
  ));
}

class _WatchFutureHook<T extends Object, R> extends Hook<AsyncSnapshot<R>> {
  const _WatchFutureHook({
    required this.instanceName,
    required this.select,
    required this.preserveState,
    this.handler,
    this.futureProvider,
    required this.initialValueProvider,
    this.executeImmediately = false,
  });
  final bool executeImmediately;
  final Future<R> Function()? futureProvider;
  final R Function() initialValueProvider;
  final void Function(BuildContext context, AsyncSnapshot<R> snapshot,
      void Function() cancel)? handler;
  final bool preserveState;
  final String? instanceName;
  final Future<R> Function(T)? select;
  @override
  _WatchFutureHookState<T, R> createState() => _WatchFutureHookState<T, R>();
}

class _WatchFutureHookState<T extends Object, R>
    extends HookState<AsyncSnapshot<R>, _WatchFutureHook<T, R>> {
  late Future<R> future;
  T? targetObject;
  late AsyncSnapshot<R> _lastValue;

  Object? _activeCallbackIdentity;

  @override
  void initHook() {
    super.initHook();
    if (hook.futureProvider == null && T is Object) {
      targetObject = GetIt.I<T>(instanceName: hook.instanceName);
      future = hook.select!(targetObject!);
    } else {
      future = hook.futureProvider!();
    }
    _lastValue = AsyncSnapshot.withData(
        ConnectionState.none, hook.initialValueProvider());

    if (hook.handler != null && hook.executeImmediately) {
      hook.handler!(this.context, _lastValue, _unsubscribe);
    }
    _subscribe();
  }

  void _subscribe() {
    final callbackIdentity = Object();
    _activeCallbackIdentity = callbackIdentity;
    future.then(
      (x) {
        if (_activeCallbackIdentity == callbackIdentity) {
          // only update if Future is still valid
          _lastValue = AsyncSnapshot.withData(ConnectionState.done, x);
          if (hook.handler == null) {
            setState(() {});
          } else {
            hook.handler?.call(this.context, _lastValue, _unsubscribe);
          }
        }
      },
      onError: (error) {
        _lastValue = AsyncSnapshot.withError(ConnectionState.done, error);
        if (hook.handler == null) {
          setState(() {});
        } else {
          hook.handler?.call(this.context, _lastValue, _unsubscribe);
        }
      },
    );
    _lastValue = _lastValue.inState(ConnectionState.waiting);
  }

  void _unsubscribe() {
    _activeCallbackIdentity = null;
  }

  @override
  AsyncSnapshot<R> build(BuildContext context) {
    /// as the select could return a different Future on different Builds
    /// we have to handle this appropriately
    if (hook.futureProvider == null) {
      // in case of allReady or isReady we don't update
      final Future<R> selectedFuture = hook.select!(targetObject!);
      if (selectedFuture != future) {
        _switchSubscription();
      }
    }
    return _lastValue;
  }

  @override
  void didUpdateHook(_WatchFutureHook<T, R> oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.futureProvider == null &&
        (oldHook.instanceName != hook.instanceName ||
            oldHook.select!(targetObject!) != future)) {
      targetObject = GetIt.I<T>(instanceName: hook.instanceName);
      _switchSubscription();
    }
  }

  void _switchSubscription() {
    future = hook.select!(targetObject!);
    if (_activeCallbackIdentity != null) {
      _unsubscribe();
      if (!hook.preserveState) {
        _lastValue = AsyncSnapshot.withData(
            ConnectionState.none, hook.initialValueProvider());
      } else {
        _lastValue = _lastValue.inState(ConnectionState.none);
        if (hook.handler != null && hook.executeImmediately) {
          hook.handler!(this.context, _lastValue, _unsubscribe);
        }
      }
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

void useStreamHandler<T extends Object, R>(
    Stream<R> Function(T) select,
    void Function(BuildContext context, AsyncSnapshot<R> newValue,
            void Function() cancel)
        handler,
    {required R initialValue,
    String? instanceName,
    bool preserveState = true}) {
  return use(_WatchStreamHook<T, R>(
    initialValue: initialValue,
    select: select,
    handler: handler,
    instanceName: instanceName,
    preserveState: preserveState,
  ));
}

void useFutureHandler<T extends Object, R>(
    Future<R> Function(T) select,
    void Function(BuildContext context, AsyncSnapshot<R> newValue,
            void Function() cancel)
        handler,
    {required R initialValue,
    String? instanceName,
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
    {void Function(BuildContext context)? onReady,
    void Function(BuildContext context, Object error)? onError,
    Duration? timeout}) {
  return use(_WatchFutureHook<Object, bool>(
    instanceName: null,
    select: null,
    preserveState: true,
    handler: (context, x, dispose) {
      if (x.hasError) {
        onError?.call(context, x.error!);
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
  )).data!;
}

bool useIsReady<T extends Object>(
    {void Function(BuildContext context)? onReady,
    void Function(BuildContext context, Object? error)? onError,
    Duration? timeout,
    String? instanceName}) {
  return use(_WatchFutureHook<Object, bool>(
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
          .then((_) => true))).data!;
}
