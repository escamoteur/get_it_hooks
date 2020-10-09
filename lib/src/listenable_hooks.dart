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
  const _WatchXHook({this.instanceName, this.select});

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
    handler = () => setState(() {});
    listenable.addListener(handler);
  }

  @override
  R build(BuildContext context) {
    return listenable.value;
  }

  @override
  void didUpdateHook(_WatchXHook<T, R> oldHook) {
    if (oldHook.instanceName != hook.instanceName ||
        oldHook.select(targetObject) != listenable) {
      listenable.removeListener(handler);
      targetObject = GetIt.I<T>(instanceName: hook.instanceName);
      listenable = hook.select(targetObject);
      listenable.addListener(handler);
    }
    super.didUpdateHook(oldHook);
  }

  @override
  void dispose() {
    listenable.removeListener(handler);
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
    this.instanceName,
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
    if (oldHook.instanceName != hook.instanceName) {
      targetObject.removeListener(handler);
      targetObject = GetIt.I<T>(instanceName: hook.instanceName);
      targetObject.addListener(handler);
    }
    super.didUpdateHook(oldHook);
  }

  @override
  void dispose() {
    targetObject.removeListener(handler);
  }

  @override
  String get debugLabel => 'useWatchX';
}
