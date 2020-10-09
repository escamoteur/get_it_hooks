library get_it_hook;

import 'package:get_it/get_it.dart';

export 'package:get_it_hooks/src/listenable_hooks.dart';

T useGetIt<T>({String instanceName, dynamic param1, param2}) {
  return GetIt.I
      .get<T>(instanceName: instanceName, param1: param1, param2: param2);
}
