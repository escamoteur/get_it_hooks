import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get_it/get_it.dart';

void pushScope({
  void Function(GetIt getIt)? init,
  void Function()? dispose,
  String? scopeName,
}) {
  use(_PushScopeHook(init: init, dispose: dispose, scopeName: scopeName));
}

class _PushScopeHook extends Hook<void> {
  const _PushScopeHook({
    this.init,
    this.scopeName,
    this.dispose,
  });

  final void Function(GetIt getIt)? init;
  final void Function()? dispose;
  final String? scopeName;

  @override
  _PushScopeHookState createState() => _PushScopeHookState();
}

class _PushScopeHookState extends HookState<void, _PushScopeHook> {
  @override
  void initHook() {
    super.initHook();
    GetIt.I.pushNewScope(scopeName: hook.scopeName, dispose: hook.dispose);
    hook.init?.call(GetIt.I);
  }

  @override
  String get debugLabel => 'usePushScopeHook';

  @override
  void build(BuildContext context) {}

  @override
  void dispose() {
    GetIt.I.popScope();
    super.dispose();
  }
}
