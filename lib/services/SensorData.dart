class SensorData {
  const SensorData(
      {this.humidity = double.nan,
      this.temperature = double.nan,
      this.dewpoint = double.nan});

  final double humidity;
  final double temperature;
  final double dewpoint;
}
