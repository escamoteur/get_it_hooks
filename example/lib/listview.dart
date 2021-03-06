import 'package:flutter/material.dart';
import 'package:flutter_weather_demo/weather_manager.dart';
import 'package:get_it_hooks/get_it_hooks.dart';

class WeatherListView extends HookWidget {
  WeatherListView();
  @override
  Widget build(BuildContext context) {
    final data = useWatchX((WeatherManager x) => x.updateWeatherCommand);

    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (BuildContext context, int index) => ListTile(
        title: Text(data[index].cityName),
        subtitle: Text(data[index].description ?? ''),
        leading: data[index].iconURL != null
            ? Image.network(
                data[index].iconURL!,
                frameBuilder: (BuildContext context, Widget child, int? frame,
                    bool wasSynchronouslyLoaded) {
                  return child;
                },
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return CircularProgressIndicator();
                },
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.error,
                  size: 40,
                ),
              )
            : SizedBox(),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${data[index].temperature}°C'),
            Text('${data[index].wind}km/h'),
          ],
        ),
      ),
    );
  }
}
