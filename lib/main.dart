import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:ht_app/components/LiveSensorData.dart';
import 'package:ht_app/services/FirebaseSensorService.dart';
import 'package:ht_app/services/FirebaseWeatherService.dart';
import 'package:ht_app/services/LocalSensorService.dart';
import 'package:ht_app/services/NotificationService.dart';
import 'package:ht_app/services/WeatherService.dart';

import 'components/LoginGuard.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final Map<String, SensorService> sensors = {
    "Living Room": FirebaseSensorService(name: 'livingroom'),
    "Living Room (local)": LocalSensorService(),
  };

  final forecastService = WeatherForecastService();
  final historicalWeatherService = FirebaseWeatherService();
  final controller = PageController();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Humidity/Temperature',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
      ),
      home: LoginGuard(
          child: PageView(
        controller: controller,
        children: sensors.entries
            .map((e) => LiveSensorData(
                title: e.key,
                sensorService: e.value,
                forecastService: forecastService,
          historicalWeatherService: historicalWeatherService,
        ))
            .toList(),
      )),
    );
  }
}
