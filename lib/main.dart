import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:multicast_dns/multicast_dns.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

final MDnsClient mDNS = MDnsClient();

void main() {
  mDNS.start();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Humidity/Temperature',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
      ),
      home: const Main(title: 'Humidity and Temperature'),
    );
  }
}

class Main extends StatefulWidget {
  const Main({super.key, required this.title});

  final String title;

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  double _temperature = double.nan;
  double _humidity = double.nan;
  double _dewpoint = double.nan;
  RefreshController _refreshController =
      RefreshController(initialRefresh: true);

  void _reloadData() async {
    try {
      final server = await mDNS
          .lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4("esp8266-ht.local"))
          .first;

      final response =
          await http.get(Uri.parse("http://${server.address.address}/ht"));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        setState(() {
          _temperature = json["temperature"];
          _humidity = json["humidity"];
          _dewpoint = json["dewpoint"];
        });
      } else {
        throw Exception('Failed to load data');
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Measurement(
                    title: "Temperature", value: _temperature, unit: "°C"),
                Measurement(title: "Humidity", value: _humidity, unit: "%"),
                Measurement(title: "Dew point", value: _dewpoint, unit: "°C"),
              ],
            ),
          )),
    );
  }
}

class Measurement extends StatelessWidget {
  const Measurement({
    Key? key,
    required String title,
    required double value,
    required String unit,
  })  : _value = value,
        _title = title,
        _unit = unit,
        super(key: key);

  final String _title;
  final double _value;
  final String _unit;

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 0),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                _title,
                style: Theme.of(context).textTheme.headline3,
              ),
              Text(
                '$_value $_unit',
                style: Theme.of(context).textTheme.headline4,
              ),
            ]));
  }
}
