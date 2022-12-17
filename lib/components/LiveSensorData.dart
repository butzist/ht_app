import 'package:flutter/material.dart';
import 'package:ht_app/components/CurrentMeasurements.dart';
import 'package:ht_app/components/TemperaturePlot.dart';
import 'package:ht_app/services/FirebaseWeatherService.dart';
import 'package:ht_app/services/LocalSensorService.dart';
import 'package:ht_app/services/NotificationService.dart';
import 'package:ht_app/services/SensorData.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tuple/tuple.dart';

import '../services/WeatherService.dart';

class LiveSensorData extends StatefulWidget {
  const LiveSensorData({
    super.key,
    required this.title,
    required this.sensorService,
    required this.historicalWeatherService,
    required this.forecastService,
  });

  final String title;
  final SensorService sensorService;
  final HistoricalWeatherService historicalWeatherService;
  final WeatherForecastService forecastService;

  @override
  State<LiveSensorData> createState() => _LiveSensorDataState();
}

class _LiveSensorDataState extends State<LiveSensorData> {
  SensorData _currentSensorData = const SensorData();
  List<Tuple2<DateTime, SensorData>> _historicalSensorData = const [];
  List<Tuple2<DateTime, SensorData>> _historicalWeatherData = const [];
  double _minOutdoorTemp = double.nan;

  final RefreshController _refreshController =
      RefreshController(initialRefresh: true);

  void _reloadData() async {
    try {
      final sensorData = await widget.sensorService.queryCurrent();
      final historicalSensorData = await widget.sensorService.queryHistory();
      final historicalWeatherData =
          await widget.historicalWeatherService.queryHistory();

      setState(() {
        _currentSensorData = sensorData;
        _historicalSensorData = historicalSensorData;
        _historicalWeatherData = historicalWeatherData;
      });

      if (_minOutdoorTemp.isNaN) {
        final forecast = await widget.forecastService.loadForecast();
        final minOutdoorTemp = widget.forecastService.minTemp(forecast);

        setState(() {
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

  Future<void> showNotification() async {
    var flip = await NotificationService.create();
    await flip.showDailyQuery();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: showNotification,
                child: const Icon(
                  Icons.add_comment,
                  size: 26.0,
                ),
              )),
        ],
      ),
      body: SmartRefresher(
          enablePullDown: true,
          enablePullUp: false,
          scrollDirection: Axis.vertical,
          header: const WaterDropMaterialHeader(),
          controller: _refreshController,
          onRefresh: _reloadData,
          child: ListView(
            children: [
              SizedBox(
                height: 400,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 60, 15, 0),
                  child: TemperaturePlot(
                      historicalSensorData: _historicalSensorData,
                      historicalWeatherData: _historicalWeatherData),
                ),
              ),
              CurrentMeasurements(
                  temperature: _currentSensorData.temperature,
                  dewpoint: _currentSensorData.dewpoint,
                  humidity: _currentSensorData.humidity,
                  minOutdoorTemp: _minOutdoorTemp),
            ],
          )),
    );
  }
}
