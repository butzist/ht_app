import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ht_app/services/SensorData.dart';
import 'package:tuple/tuple.dart';

class TemperaturePlot extends StatelessWidget {
  const TemperaturePlot({
    super.key,
    required this.historicalSensorData,
  });

  final List<Tuple2<DateTime, SensorData>> historicalSensorData;

  LineChartData get _chartData {
    final now = DateTime.now();

    return LineChartData(
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
  }

  @override
  Widget build(BuildContext context) {
    return LineChart(_chartData);
  }
}
