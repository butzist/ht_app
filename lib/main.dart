import 'package:flutter/material.dart';
import 'package:ht_app/services/sensor.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import "services/weather.dart";

final MDnsClient mDNS = MDnsClient();

void main() {
  mDNS.start();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Humidity/Temperature',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
      ),
      home: const Main(title: 'Humidity and Temperature'),
    );
  }
}

class Main extends StatefulWidget {
  const Main({super.key, required this.title});

  final String title;

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  SensorData _sensorData = const SensorData(
      humidity: double.nan, temperature: double.nan, dewpoint: double.nan);
  Forecast _forecast = const Forecast(timestamps: [], temperature: []);
  double _minOutdoorTemp = double.nan;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: true);

  void _reloadData() async {
    try {
      final sensorData = await querySensor(mDNS);
      final forecast = await loadForecast();
      final minOutdoorTemp = minTemp(forecast);

      setState(() {
        _sensorData = sensorData;
        _forecast = forecast;
        _minOutdoorTemp = minOutdoorTemp;
      });

      _refreshController.refreshCompleted();
    } catch (ex) {
      _refreshController.refreshFailed();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error fetching data: $ex"),
        backgroundColor: Theme.of(context).errorColor,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SmartRefresher(
          enablePullDown: true,
          enablePullUp: false,
          header: const WaterDropMaterialHeader(),
          controller: _refreshController,
          onRefresh: _reloadData,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Measurement(
                    title: "Temperature",
                    value: _sensorData.temperature,
                    unit: "°C"),
                Measurement(
                    title: "Humidity", value: _sensorData.humidity, unit: "%"),
                Measurement(
                    title: "Dew point",
                    value: _sensorData.dewpoint,
                    unit: "°C"),
                Measurement(
                    title: "Min Temp.",
                    value: _minOutdoorTemp,
                    unit: "°C"),
              ],
            ),
          )),
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
