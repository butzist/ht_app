import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multicast_dns/multicast_dns.dart';

import 'SensorData.dart';

abstract class SensorService {
  Future<SensorData> query();
}

class LocalSensorService implements SensorService {
  final MDnsClient _mDNS = MDnsClient();

  @override
  Future<SensorData> query() async {
    await _mDNS.start();
    final server = await _mDNS
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
}
