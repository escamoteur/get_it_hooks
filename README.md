# get_it_hooks

This package offers a set of hooks for Remi Rousselet's (flutter_hooks)[https://pub.dev/packages/flutter_hooks] package, that makes the binding of data that is stored within `GetIt` really easy.

>When I write of binding, I mean a mechanism that will automatically rebuild a widget that if data it depends on changes 

These hooks offer the exact same functionality as `get_it_mixin`. You may ask why then also hooks? The reason is that `flutter_hooks` and `get_it_mixin` try both to override the `createElement()` function of the widget which means you could not use the mixin together with any hooks and vice versa.

## Getting started
>For this readme I expect that you know how to work with [GetIt](https://pub.dev/packages/get_it)

Lets create some model class that we want to access with the mixins:

```Dart
class Model extends ChangeNotifier {
  String _country;
  set country(String val) {
    _country = val;
    notifyListeners();
  }
  String get country => _country;

  String _emailAddress;
  set country(String val) {
    _emailAddress = val;
    notifyListeners();
  }
  String get emailAddress => _emailAddress;

  final ValueNotifier<String> name;
  final Model nestedModel;

  Stream<String> userNameUpdates; 
  Future get initializationReady;
}
```

No we will explore how to access the different properties by using the `get_it_hooks`. To make this work you have to add `flutter_hooks` to your dependencies alongside `get_it_hooks`.


### Reading Data

As all hooks `get_it_hooks` start with `use...`. The easiest ones are `useGet()` and `useGetX()` which will access data from `GetIt` as if you would to `GetIt.I<Type>()`

```Dart
class TestStateLessWidget extends HookWidget{

  @override
  Widget build(BuildContext context) {
    final email = get<Model>().emailAddress;
    return Column(
      children: [
        Text(email),
        Text(useGetX((Model x) => x.country, instanceName: 'secondModell')),
      ],
    );
  }
}
```

As you can see `useGet()` is used exactly like using `GetIt` directly with all its parameters. `useGetX()` does the same but offers a selector function that has to return the final value from the referenced object. Most of the time you probably will only use `useGet()`, but the selector function can be used to do any data processing that might me needed before you can use the value.

**useGet() and useGetX() can be called multiple times inside a Widget and also outside the `build()` function.** Because they are no real hooks but just convenience functions.

### Watching Data
The following functions will return a value and rebuild the widget every-time this data inside GetIt changes. 
**Important: All following functions can only be called inside the `build()` function. Also all of these function have to be called always and in the same order on every `build` meaning they can't be called conditionally otherwise the hooks gets confused**

Imagine you have an object inside `GetIt` registered that implements `ValueListenableBuilder<String>` named `currentUserName` and we want the above widget to rebuild every-time it's value changes.
We could do this adding a `ValueListenableBuilder`:


```Dart
class TestStateLessWidget1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<String>(
          valueListenable: GetIt.I<ValueListenable<String>>(instanceName: 'currentUser'),
          builder: (context, val,_) {
            return Text(val);
          }
        ),
      ],
    );
  }
}
```

With the hooks we can now write this:

```Dart
class TestStateLessWidget1 extends HookWidget{
  @override
  Widget build(BuildContext context) {
    final currentUser = 
       useWatch<ValueListenable<String>, String>(instanceName: 'currentUser');

    return Column(
      children: [
         Text(currentUser)
      ],
    );
  }
}
```

Unfortunately we have to provide a second generic parameter because Dart can't infer the type of the return value. Luckily we will see with the following functions there is a way to help the compiler.

#### useWatchX
In a real app it's way more probable that your business object wont be the `ValueListenable` itself but it will have some properties that might be `ValueListenables` like the `name` property of our `Model` class. To react to changes to of such properties you can use `useWatchX()`:

```Dart
class TestStateLessWidget1 extends HookWidget{
  @override
  Widget build(BuildContext context) {
    final name = useWatchX((Model x) => x.name);
    /// if the valueListenable is nested deeper in you object
    final innerName = useWatchX((Model x) => x.nestedModel.name);

    return Column(
      children: [
        Text(name),
        Text(innerName),
      ],
    );
  }
}
```

This widget will rebuild whenever one of the watched `ValueListenables` changes.

You might be wondering why I did not pass the type `Model` as generic Parameter to `useWatchX()`. The reason it that the signature of it looks like this:

```Dart
R useWatchX<T, R>(
    ValueListenable<R> Function(T x) select, {
    String instanceName,
  }) =>
```
which means you would have to pass two generic types, not only `T` but also `R`. If you pass `T` inside the `select` function the compiler is able to infer `R`. 

#### useWatchOnly & useWatchXonly
Another popular pattern is that a business object implements `Listenable` like `ChangeNotifier` and it will notify its listeners whenever one of its properties changes. As we want to only rebuild a Widget when a value that it needs is updated `useWatchOnly()` lets you define which property you want to observe and it will only trigger the rebuild if it really changes.
`useWatchXonly()` does the same but for nested `Listenables`

```Dart
class TestStateLessWidget1 extends HookWidget{
  @override
  Widget build(BuildContext context) {
    final country = useWatchOnly((Model x) => x.country);
    /// if the watched property is nested deeper in you object
    final innerEmail = useWatchXOnly((Model x) => x.nestedModel,(Model o)=>o.emailAddress);

    return Column(
      children: [
        Text(country),
        Text(innerEamil),
      ],
    );
  }
}
```

This Widget will rebuild when either `country` of the `Model` object or `emailAddress` of the nested `Model` changes. If you update `emailAddress` of `Model` it won't update although it too calls `notifyListeners`

If you want to get an update whenever `Model` triggers `notifyListener` you can achieve this by using this selector method:

```Dart
final model = useWatchOnly((Model x) => x);
```

#### Streams and Futures
In case you want to update your widget as soon as a Stream in your Model emits a new value or as soon as a `Future` completes you can use `useWatchStream` and `useWatchFuture`. The nice thing is that you don't have to care to cancel subscriptions, hooks takes care of that. So instead of using a `StreamBuilder` you can just do:

```Dart
class TestStateLessWidget1 extends HookWidget{
  @override
  Widget build(BuildContext context) {
    final currentUser = useWatchStream((Model x) => x.userNameUpdates, 'NoUser');
    final ready =
        useWatchFuture((Model x) => x.initializationReady,false).data;

    return Column(
      children: [
        if (ready != true || !currentUser.hasData) // in case of an error ready could be null
         CircularProgressIndicator()
         else
        Text(currentUser.data),
      ],
    );
  }
}
```

These functions can handle if the selector function returns different Streams and Futures on following `build` calls. In this case the old subscription is cancelled and the new `Stream` subscribed. Check he API docs for more details.


### Event handlers
Maybe you don't need a value updated but want to show a Snackbar as soon as a `Stream` emits a value or a `ValueListenable` updates a value or a `Future`. If you wanted to do this without this mix_in you would need a `StatefulWidget` where you subscribe to a `Stream` in `iniState` and dispose your subscription in the `dispose` function of the `State`.

With hooks you can register handlers for `Streams`, `ValueListenables` and `Futures`, and hooks will dispose everything for you as soon as the widget gets destroyed.

```Dart
class TestStateLessWidget1 extends StatelessWidget with GetItMixin {
  @override
  Widget build(BuildContext context) {
    /// Registers a handler for a valueListenable
    useRegisterHandler((Model x) => x.name, (context,name,_) 
        => showNameDialog(context,name));
        
    useRegisterStreamHandler((Model x) => x.userNameUpdates, (context,name,_) 
        => showNameDialog(context,name));

    useRegisterFutureHandler((Model x) => x.initializationReady, (context,__,_) 
        => Navigator.of(contex).push(....));
    return Column(
      children: [
        //...whatever widgets needed 
      ],
    );
  }
}
```
For instance you could register a handler for `thrownExceptions` of a `flutter_command` while you use `useWatch()` to get the values.

In the example above you see that the handler function has a third parameter that we ignored. Your handler gets a dispose function passed there that a handler could use to kill a registration from within itself.

### useAllReady() & useIsReady()
If you already used the synchronization functions from GetIt you know both of this functions (otherwise check them out in the GetIt readme). The hook variant returns the actual status as `bool` value and triggers a rebuild when this status changes. Additionally you can register handlers that are called when the status is `true`.

```Dart
class TestStateLessWidget1 extends HooksWidget{
  @override
  Widget build(BuildContext context) {
    final isReady = useAllReady();

    if (isReady) {
      return MyMainPageContent();
    } else {
      return CircularProgressIndicator();
    }
}
```
or with the handler:

```Dart
class TestStateLessWidget1 extends Widget{
  @override
  Widget build(BuildContext context) {
    useAllReady(
      onReady: (context) =>
          Navigator.of(context).pushReplacement(MainPageRoute()));

  return CircularProgressIndicator();
  }
}
```
`useIsReady<T>()` can be used in the same way to react on the status of a single asynchronous singleton.

### Pushing a new GetIt Scope
With `usePushScope()` you can push one scope that will be popped when the Widget/State is destroyed. 
You can pass an `init` function that will be called immediately after the scope was pushed and an optional `dispose` function that is called directly before the scope is popped.

```Dart
  void usePushScope({void Function(GetIt getIt) init, void Function() dispose});
```

## StatefulWidgets
Instead of a `StatefulWidget` you have to use a `StatefulHookWidget`. Otherwise there are no differences to `HookWidget`.