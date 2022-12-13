import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:multicast_dns/multicast_dns.dart';
import 'package:quiver/time.dart';
import 'package:tuple/tuple.dart';

import 'SensorData.dart';

abstract class SensorService {
  Future<SensorData> queryCurrent();
  Future<List<Tuple2<DateTime, SensorData>>> queryHistory();
}

class LocalSensorService implements SensorService {
  final MDnsClient _mDNS = MDnsClient();
  final List<Tuple2<DateTime, SensorData>> _history = [];

  @override
  Future<SensorData> queryCurrent() async {
    await _mDNS.start();
    final server = await _mDNS
        .lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4("esp8266-ht.local"))
        .first;

    final response =
        await http.get(Uri.parse("http://${server.address.address}/ht"));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final data = SensorData(
          humidity: json["humidity"],
          temperature: json["temperature"],
          dewpoint: json["dewpoint"]);

      _history.add(Tuple2(DateTime.now(), data));
      return data;
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Future<List<Tuple2<DateTime, SensorData>>> queryHistory() async {
    return _history
        .where(
            (element) => element.item1.isAfter(DateTime.now().subtract(aDay)))
        .toList();
  }
}
