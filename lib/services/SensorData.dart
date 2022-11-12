import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multicast_dns/multicast_dns.dart';

class SensorData {
  const SensorData(
      {this.humidity = double.nan,
      this.temperature = double.nan,
      this.dewpoint = double.nan});

  final double humidity;
  final double temperature;
  final double dewpoint;
}

