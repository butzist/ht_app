import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multicast_dns/multicast_dns.dart';

class SensorData {
  const SensorData(
      {required this.humidity,
      required this.temperature,
      required this.dewpoint});

  final double humidity;
  final double temperature;
  final double dewpoint;
}

Future<SensorData> querySensor(MDnsClient mDNS) async {
  final server = await mDNS
      .lookup<IPAddressResourceRecord>(
          ResourceRecordQuery.addressIPv4("esp8266-ht.local"))
      .first;

  final response =
      await http.get(Uri.parse("http://${server.address.address}/ht"));

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    return SensorData(
        humidity: json["humidity"],
        temperature: json["temperature"],
        dewpoint: json["dewpoint"]);
  } else {
    throw Exception('Failed to load data');
  }
}
