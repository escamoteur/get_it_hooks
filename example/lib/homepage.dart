import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_weather_demo/weather_manager.dart';
import 'package:functional_listener/functional_listener.dart';
import 'package:get_it_hooks/get_it_hooks.dart';

import 'listview.dart';

class HomePage extends StatefulHookWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ListenableSubscription? errorSubscription;

  @override
  void didChangeDependencies() {
    errorSubscription ??= useGet<WeatherManager>()
        .updateWeatherCommand
        .thrownExceptions
        .where((x) => x != null) // filter out the error value reset
        .listen((error, _) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('An error has occurred!'),
                content: Text(error.toString()),
              ));
    });
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    errorSubscription!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRunning =
        useWatchX((WeatherManager x) => x.updateWeatherCommand.isExecuting);
    final updateButtonEnbaled =
        useWatchX((WeatherManager x) => x.updateWeatherCommand.canExecute);
    final switchValue =
        useWatchX((WeatherManager x) => x.setExecutionStateCommand);

    return Scaffold(
      appBar: AppBar(title: Text("WeatherDemo")),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: TextField(
              autocorrect: false,
              decoration: InputDecoration(
                hintText: "Filter cities",
                hintStyle: TextStyle(color: Color.fromARGB(150, 0, 0, 0)),
              ),
              style: TextStyle(
                fontSize: 20.0,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
              onChanged: useGet<WeatherManager>().textChangedCommand,
            ),
          ),
          Expanded(
            // Handle events to show / hide spinner
            child: Stack(
              children: [
                WeatherListView(),
                // if true we show a busy Spinner otherwise the ListView
                if (isRunning == true)
                  Center(
                    child: Container(
                      width: 50.0,
                      height: 50.0,
                      child: CircularProgressIndicator(),
                    ),
                  )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            // We use a ValueListenableBuilder to toggle the enabled state of the button
            child: Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    child: Text("Update"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 33, 150, 243),
                        textStyle: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255))),
                    onPressed: updateButtonEnbaled
                        ? useGet<WeatherManager>().updateWeatherCommand.call
                        : null,
                  ),
                ),
                Switch(
                    value: switchValue,
                    onChanged:
                        useGet<WeatherManager>().setExecutionStateCommand),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
