import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:quiver/iterables.dart';
import 'package:quiver/time.dart';

class Forecast {
  const Forecast({required this.timestamps, required this.temperature});

  final List<int> timestamps;
  final List<double> temperature;
}

Future<Forecast> loadForecast() async {
  final response = await http.get(Uri.parse(
      "https://api.open-meteo.com/v1/forecast?latitude=47.44&longitude=8.47&hourly=temperature_2m&timeformat=unixtime&past_days=1"));

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    return Forecast(
        timestamps: List<int>.from(json["hourly"]["time"]),
        temperature: List<double>.from(json["hourly"]["temperature_2m"]));
  } else {
    throw Exception('Failed to load data');
  }
}

double minTemp(Forecast forecast) {
  final unixTimeNow = DateTime.now().millisecondsSinceEpoch / 1000;
  final unixTimeTomorrow = DateTime.now().add(aDay).millisecondsSinceEpoch / 1000;
  return min(zip([forecast.timestamps, forecast.temperature]).where((pair) => pair[0] >= unixTimeNow && pair[0] <= unixTimeTomorrow).map((e) => e[1])) as double;
}
