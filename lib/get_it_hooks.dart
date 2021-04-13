library get_it_hook;

import 'package:get_it/get_it.dart';

export 'package:flutter_hooks/flutter_hooks.dart';
export 'package:get_it_hooks/src/basic_hooks.dart';
export 'package:get_it_hooks/src/listenable_hooks.dart';
export 'package:get_it_hooks/src/scope_hooks.dart';
export 'package:get_it_hooks/src/stream_future_hooks.dart';

T useGetIt<T extends Object>({String? instanceName, dynamic param1, param2}) {
  return GetIt.I
      .get<T>(instanceName: instanceName, param1: param1, param2: param2);
}
