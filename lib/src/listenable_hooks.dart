import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get_it/get_it.dart';

R useWatch<T extends ValueListenable<R>, R>({String instanceName}) {
  return useValueListenable(GetIt.I<T>(instanceName: instanceName));
}

R useWatchX<T, R>(
  ValueListenable<R> Function(T) select, {
  String instanceName,
}) {
  assert(select != null, 'select can not be null in useWatchX');
  return use(_WatchXHook<T, R>(
    select: select,
    instanceName: instanceName,
  ));
}

class _WatchXHook<T, R> extends Hook<R> {
  const _WatchXHook(
      {@required this.instanceName,
      @required this.select,
      this.handler,
      this.executeImmediately = false});

  final bool executeImmediately;
  final void Function(BuildContext context, R newValue, void Function() cancel)
      handler;
  final String instanceName;
  final ValueListenable<R> Function(T) select;
  @override
  _WatchXHookState<T, R> createState() => _WatchXHookState<T, R>();
}

class _WatchXHookState<T, R> extends HookState<R, _WatchXHook<T, R>> {
  ValueListenable<R> listenable;
  VoidCallback handler;
  T targetObject;

  @override
  void initHook() {
    super.initHook();
    targetObject = GetIt.I<T>(instanceName: hook.instanceName);
    listenable = hook.select(targetObject);
    assert(listenable != null, 'select returned null in useWatchX');
    _subscribe();
    if (hook.handler != null && hook.executeImmediately) {
      hook.handler(this.context, listenable.value, _unsubscribe);
    }
  }

  void _subscribe() {
    handler = () {
      if (hook.handler == null) {
        setState(() {});
      } else {
        hook.handler(context, listenable.value, _unsubscribe);
      }
    };
    listenable.addListener(handler);
  }

  @override
  R build(BuildContext context) {
    return listenable.value;
  }

  @override
  void didUpdateHook(_WatchXHook<T, R> oldHook) {
    super.didUpdateHook(oldHook);
    if (oldHook.instanceName != hook.instanceName ||
        oldHook.select(targetObject) != listenable) {
      _unsubscribe();
      targetObject = GetIt.I<T>(instanceName: hook.instanceName);
      listenable = hook.select(targetObject);
      _subscribe();
      if (hook.handler != null && hook.executeImmediately) {
        hook.handler(this.context, listenable.value, _unsubscribe);
      }
    }
  }

  void _unsubscribe() {
    listenable.removeListener(handler);
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  String get debugLabel => 'useWatchX';
}

R useWatchOnly<T extends Listenable, R>(
  R Function(T) only, {
  String instanceName,
}) {
  assert(only != null, 'only can not be null in useWatchOnly');
  return use(_WatchOnlyHook<T, R>(
    only: only,
    instanceName: instanceName,
  ));
}

class _WatchOnlyHook<T extends Listenable, R> extends Hook<R> {
  const _WatchOnlyHook({
    @required this.instanceName,
    @required this.only,
  });

  final String instanceName;
  final R Function(T) only;
  @override
  _WatchOnlyHookState<T, R> createState() => _WatchOnlyHookState<T, R>();
}

class _WatchOnlyHookState<T extends Listenable, R>
    extends HookState<R, _WatchOnlyHook<T, R>> {
  VoidCallback handler;
  T targetObject;
  R lastValue;

  @override
  void initHook() {
    super.initHook();
    targetObject = GetIt.I<T>(instanceName: hook.instanceName);
    lastValue = hook.only(targetObject);
    handler = () {
      final currentValue = hook.only(targetObject);
      if (currentValue != lastValue) {
        setState(() {
          lastValue = currentValue;
        });
      }
    };
    targetObject.addListener(handler);
  }

  @override
  R build(BuildContext context) {
    return lastValue;
  }

  @override
  void didUpdateHook(_WatchOnlyHook<T, R> oldHook) {
    super.didUpdateHook(oldHook);
    if (oldHook.instanceName != hook.instanceName) {
      targetObject.removeListener(handler);
      targetObject = GetIt.I<T>(instanceName: hook.instanceName);
      targetObject.addListener(handler);
    }
  }

  @override
  void dispose() {
    targetObject.removeListener(handler);
    super.dispose();
  }

  @override
  String get debugLabel => 'useWatchX';
}

R useWatchXOnly<T, Q extends Listenable, R>(
  Q Function(T) select,
  R Function(Q listenable) only, {
  String instanceName,
}) {
  assert(only != null, 'only can not be null in useWatchXOnly');
  assert(select != null, 'select can not be null in useWatchXOnly');
  return use(_WatchXonlyHook<T, Q, R>(
      select: select, only: only, instanceName: instanceName));
}

class _WatchXonlyHook<T, Q extends Listenable, R> extends Hook<R> {
  const _WatchXonlyHook({
    @required this.select,
    @required this.only,
    @required this.instanceName,
  });

  final Q Function(T) select;
  final R Function(Q listenable) only;
  final String instanceName;
  @override
  _WatchXonlyHookState<T, Q, R> createState() =>
      _WatchXonlyHookState<T, Q, R>();
}

class _WatchXonlyHookState<T, Q extends Listenable, R>
    extends HookState<R, _WatchXonlyHook<T, Q, R>> {
  Listenable listenable;
  VoidCallback handler;
  T targetObject;
  R lastValue;

  @override
  void initHook() {
    super.initHook();
    targetObject = GetIt.I<T>(instanceName: hook.instanceName);
    listenable = hook.select(targetObject);
    assert(listenable != null, 'select returned null in useWatchXonly');
    lastValue = hook.only(listenable);
    handler = () {
      final currentValue = hook.only(listenable);
      if (currentValue != lastValue) {
        setState(() {
          lastValue = currentValue;
        });
      }
    };
    listenable.addListener(handler);
  }

  @override
  R build(BuildContext context) {
    return lastValue;
  }

  @override
  void didUpdateHook(_WatchXonlyHook<T, Q, R> oldHook) {
    super.didUpdateHook(oldHook);
    if (oldHook.instanceName != hook.instanceName ||
        oldHook.select(targetObject) != listenable) {
      listenable.removeListener(handler);
      targetObject = GetIt.I<T>(instanceName: hook.instanceName);
      listenable = hook.select(targetObject);
      lastValue = hook.only(listenable);
      listenable.addListener(handler);
    }
  }

  @override
  void dispose() {
    listenable.removeListener(handler);
    super.dispose();
  }

  @override
  String get debugLabel => 'useWatchXonly';
}

void useRegisterHandler<T, R>(
  ValueListenable<R> Function(T) select,
  void Function(BuildContext context, R newValue, void Function() cancel)
      handler, {
  bool executeImmediately = false,
  String instanceName,
}) {
  use(_WatchXHook<T, R>(
      instanceName: instanceName,
      select: select,
      executeImmediately: executeImmediately,
      handler: handler));
}
