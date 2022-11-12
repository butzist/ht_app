import 'package:flutter/material.dart';
import 'package:ht_app/components/CurrentMeasurements.dart';
import 'package:ht_app/services/LocalSensorService.dart';
import 'package:ht_app/services/SensorData.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../services/WeatherService.dart';

class LiveSensorData extends StatefulWidget {
  const LiveSensorData(
      {super.key,
      required this.title,
      required this.sensorService,
      required this.weatherService});

  final String title;
  final SensorService sensorService;
  final WeatherService weatherService;

  @override
  State<LiveSensorData> createState() => _LiveSensorDataState();
}

class _LiveSensorDataState extends State<LiveSensorData> {
  SensorData _sensorData = const SensorData();
  Forecast _forecast = const Forecast(timestamps: [], temperature: []);
  double _minOutdoorTemp = double.nan;

  final RefreshController _refreshController =
      RefreshController(initialRefresh: true);

  void _reloadData() async {
    try {
      final sensorData = await widget.sensorService.query();

      setState(() {
        _sensorData = sensorData;
      });

      if (_minOutdoorTemp.isNaN) {
        final forecast = await widget.weatherService.loadForecast();
        final minOutdoorTemp = widget.weatherService.minTemp(forecast);

        setState(() {
          _forecast = forecast;
          _minOutdoorTemp = minOutdoorTemp;
        });
      }

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
            child: CurrentMeasurements(
                temperature: _sensorData.temperature,
                dewpoint: _sensorData.dewpoint,
                humidity: _sensorData.humidity,
                minOutdoorTemp: _minOutdoorTemp),
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
