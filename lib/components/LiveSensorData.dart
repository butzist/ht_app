import 'package:fl_chart/fl_chart.dart';
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
  SensorData _currentSensorData = const SensorData();
  LineChartData _chartData = LineChartData();
  Forecast _forecast = const Forecast(timestamps: [], temperature: []);
  double _minOutdoorTemp = double.nan;

  final RefreshController _refreshController =
      RefreshController(initialRefresh: true);

  void _reloadData() async {
    try {
      final sensorData = await widget.sensorService.queryCurrent();

      setState(() {
        _currentSensorData = sensorData;
      });

      final historicalSensorData = await widget.sensorService.queryHistory();
      final now = DateTime.now();
      final chartData = LineChartData(
          titlesData: FlTitlesData(
            show: true,
            leftTitles: AxisTitles(
                sideTitles: SideTitles(reservedSize: 40, showTitles: true)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(reservedSize: 40, showTitles: true),
            ),
            topTitles: AxisTitles(),
            rightTitles: AxisTitles(),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: historicalSensorData
                  .map((entry) => FlSpot(
                        entry.item1.difference(now).inSeconds / 3600,
                        entry.item2.temperature,
                      ))
                  .toList(),
            ),
            LineChartBarData(
              spots: historicalSensorData
                  .map((entry) => FlSpot(
                        entry.item1.difference(now).inSeconds / 3600,
                        entry.item2.dewpoint,
                      ))
                  .toList(),
            ),
          ]);

      setState(() {
        _chartData = chartData;
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
          child: Column(
            children: [
              SizedBox(
                height: 400,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0, 80, 15, 0),
                  child: LineChart(_chartData),
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
