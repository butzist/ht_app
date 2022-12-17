import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ht_app/services/SensorData.dart';
import 'package:tuple/tuple.dart';

class TemperaturePlot extends StatelessWidget {
  const TemperaturePlot({
    super.key,
    required this.historicalSensorData,
    required this.historicalWeatherData,
  });

  final List<Tuple2<DateTime, SensorData>> historicalSensorData;
  final List<Tuple2<DateTime, SensorData>> historicalWeatherData;

  LineChartData get _chartData {
    final now = DateTime.now();
    final dotData = FlDotData(
      getDotPainter: (spot, dbl, data, index) =>
          FlDotCrossPainter(color: Colors.black, size: 4, width: 1),
    );
    const barWidth = 3.0;

    return LineChartData(
        backgroundColor: Colors.lightBlueAccent.withAlpha(30),
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
            barWidth: barWidth,
            color: const Color.fromRGBO(150, 0, 0, 1),
            dotData: dotData,
            spots: historicalSensorData
                .map((entry) => FlSpot(
                      entry.item1.difference(now).inSeconds / 3600,
                      entry.item2.temperature,
                    ))
                .toList(),
          ),
          LineChartBarData(
            barWidth: barWidth,
            color: const Color.fromRGBO(0, 150, 0, 1),
            dotData: dotData,
            spots: historicalSensorData
                .map((entry) => FlSpot(
                      entry.item1.difference(now).inSeconds / 3600,
                      entry.item2.dewpoint,
                    ))
                .toList(),
          ),
          LineChartBarData(
            barWidth: barWidth,
            color: const Color.fromRGBO(50, 200, 250, 1),
            dotData: dotData,
            spots: historicalWeatherData
                .map((entry) => FlSpot(
                      entry.item1.difference(now).inSeconds / 3600,
                      entry.item2.temperature,
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
