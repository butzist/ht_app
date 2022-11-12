import 'package:flutter/material.dart';

class CurrentMeasurements extends StatelessWidget {
  const CurrentMeasurements({
    super.key,
    required this.temperature,
    required this.humidity,
    required this.dewpoint,
    required this.minOutdoorTemp,
  });

  final double temperature;
  final double humidity;
  final double dewpoint;
  final double minOutdoorTemp;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Measurement(title: "Temperature", value: temperature, unit: "°C"),
        Measurement(title: "Humidity", value: humidity, unit: "%"),
        Measurement(title: "Dew point", value: dewpoint, unit: "°C"),
        Measurement(title: "Min Temp.", value: minOutdoorTemp, unit: "°C"),
      ],
    );
  }
}

class Measurement extends StatelessWidget {
  const Measurement({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
  });

  final String title;
  final double value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 0),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.headline3,
              ),
              Text(
                '$value $unit',
                style: Theme.of(context).textTheme.headline4,
              ),
            ]));
  }
}
