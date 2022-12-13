import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  static Future<void> showDailyNotification(
      FlutterLocalNotificationsPlugin flip) async {
    await showDailyQuery(flip);

    // only run between 7:00 and 8:00
    if (systemTime().hour == 7) {
      await showDailyQuery(flip);
    }

    // only run between 20:00 and 21:00
    if (systemTime().hour == 20) {
      await showDailyReminder(flip);
    }
  }

  static Future<void> showDailyReminder(
      FlutterLocalNotificationsPlugin flip) async {
    var platformChannelSpecifics = const NotificationDetails(
      android: AndroidNotificationDetails(
          'de.szalkowski.ht-app.daily', 'Daily status',
          channelDescription: "Emits daily status between 20:00 and 21:00",
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation('')),
    );

    try {
      var sensor = LocalSensorService();
      var data = await sensor.query();

      await flip.show(
          0,
          "Current Temperature/Humidity",
          "Temperature: ${data.temperature}\nDewpoint: ${data.dewpoint}\nHumidity: ${data.humidity}",
          platformChannelSpecifics,
          payload: 'status');
    } catch (err) {
      await flip.show(0, "Error", "Temperature fetching error: $err",
          platformChannelSpecifics,
          payload: 'error');
    }
  }

  static Future<void> showDailyQuery(
      FlutterLocalNotificationsPlugin flip) async {
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

    await flip.show(0, "Are windows fogged?", "Select an option below",
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

    FlutterLocalNotificationsPlugin flip = FlutterLocalNotificationsPlugin();
    var android = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var settings = InitializationSettings(
      android: android,
    );

    await flip.initialize(
      settings,
      onDidReceiveNotificationResponse: onNotificationResponse,
    );
    await NotificationService.showDailyNotification(flip);
    return true;
  });
}

onNotificationResponse(NotificationResponse notificationResponse) {
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
      return;
  }

  setFogLevel(fogLevel);
}

@pragma('vm:entry-point')
onBackgroundNotificationResponse(
    NotificationResponse notificationResponse) async {
  print("background notification response");

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await onNotificationResponse(notificationResponse);
}

setFogLevel(int fogLevel) async {
  var currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  var db = FirebaseDatabase.instance.ref("annotations/$currentTime");
  try {
    await db.set({"fogLevel": fogLevel});
  } catch (err) {
    print(err);
  }
}
