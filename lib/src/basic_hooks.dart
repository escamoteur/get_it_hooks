import 'package:get_it/get_it.dart';

/// Not really hooks but convenients

T useGet<T extends Object>(
        {String? instanceName, dynamic param1, dynamic param2}) =>
    GetIt.I.get<T>(instanceName: instanceName, param1: param1, param2: param2);

/// like [get] but for async registrations
Future<T> useGetAsync<T extends Object>(
        {String? instanceName, dynamic param1, dynamic param2}) =>
    GetIt.I.getAsync<T>(
        instanceName: instanceName, param1: param1, param2: param2);

/// like [get] but with an additional [select] function to return a member of [T]
R useGetX<T extends Object, R>(R Function(T) accessor, {String? instanceName}) {
  return accessor(GetIt.I<T>(instanceName: instanceName));
}
