import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ht_app/services/FirebaseAnnotationService.dart';
import 'package:quiver/time.dart';
import 'package:workmanager/workmanager.dart';

import '../firebase_options.dart';
import 'LocalSensorService.dart';

class NotificationService {
  static Future<void> initialize() async {
    var workManager = Workmanager();
    await workManager.initialize(callbackDispatcher);
    await workManager.registerPeriodicTask(
      'de.szalkowski.ht-app.daily',
      "daily",
      frequency: const Duration(hours: 1),
    );
  }

  final FlutterLocalNotificationsPlugin _flip =
      FlutterLocalNotificationsPlugin();

  NotificationService._create();

  static Future<NotificationService> create() async {
    var service = NotificationService._create();
    var android = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var settings = InitializationSettings(
      android: android,
    );

    await service._flip.initialize(
      settings,
      onDidReceiveNotificationResponse: service._onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationResponse,
    );

    return service;
  }

  _onNotificationResponse(NotificationResponse notificationResponse) async {
    print("notification response");

    int fogLevel;
    switch (notificationResponse.actionId) {
      case "fog_0":
        fogLevel = 0;
        break;
      case "fog_1":
        fogLevel = 1;
        break;
      case "fog_2":
        fogLevel = 2;
        break;
      default:
        throw Exception("unexpected notification response");
    }

    FirebaseAnnotationService annotations = FirebaseAnnotationService();
    await annotations.setFogLevel(fogLevel);
  }

  Future<void> showDailyNotification() async {
    try {
      // only run between 7:00 and 8:00
      if (systemTime().hour == 7) {
        await showDailyQuery();
      }

      // only run between 20:00 and 21:00
      if (systemTime().hour == 20) {
        await showDailyReminder();
      }
    } catch (err) {
      await showError(err.toString());
    }
  }

  Future<void> showError(String message) async {
    var platformChannelSpecifics = const NotificationDetails(
      android: AndroidNotificationDetails('de.szalkowski.ht-app.error', 'Error',
          channelDescription:
              "Emits errors happening during background actions",
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation('')),
    );

    await _flip.show(0, "Error", message, platformChannelSpecifics,
        payload: 'error');
  }

  Future<void> showDailyReminder() async {
    var platformChannelSpecifics = const NotificationDetails(
      android: AndroidNotificationDetails(
          'de.szalkowski.ht-app.daily', 'Daily status',
          channelDescription: "Emits daily status between 20:00 and 21:00",
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation('')),
    );

    var sensor = LocalSensorService();
    var data = await sensor.queryCurrent();

    await _flip.show(
        0,
        "Current Temperature/Humidity",
        "Temperature: ${data.temperature}\nDewpoint: ${data.dewpoint}\nHumidity: ${data.humidity}",
        platformChannelSpecifics,
        payload: 'status');
  }

  Future<void> showDailyQuery() async {
    var platformChannelSpecifics = const NotificationDetails(
      android: AndroidNotificationDetails(
        'de.szalkowski.ht-app.daily',
        'Daily query',
        channelDescription: "Queries daily status between 7:00 and 8:00",
        importance: Importance.max,
        priority: Priority.high,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction('fog_2', 'Yes'),
          AndroidNotificationAction('fog_0', 'No'),
          AndroidNotificationAction('fog_1', 'A Bit'),
        ],
      ),
    );

    await _flip.show(0, "Are windows fogged?", "Select an option below",
        platformChannelSpecifics,
        payload: 'query');
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  print("callback");

  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().executeTask((task, inputData) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    var flip = await NotificationService.create();
    await flip.showDailyNotification();
    return true;
  });
}

@pragma('vm:entry-point')
onBackgroundNotificationResponse(
    NotificationResponse notificationResponse) async {
  print("background notification response");

  var flip = await NotificationService.create();
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await flip._onNotificationResponse(notificationResponse);
  } catch (err) {
    await flip.showError(err.toString());
  }
}
