import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quiver/time.dart';
import 'package:workmanager/workmanager.dart';

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
    // only run between 20:00 and 21:00
    if (systemTime().hour != 20) {
      return;
    }

    var platformChannelSpecifics = const NotificationDetails(
      android: AndroidNotificationDetails(
          'de.szalkowski.ht-app.daily', 'Daily status',
          channelDescription: "Emits daily status between 20:00 and 21:00",
          importance: Importance.max,
          priority: Priority.high),
    );

    try {
      var sensor = LocalSensorService();
      var data = await sensor.query();

      await flip.show(
          0,
          "Current Temperature/Humidity",
          "Temperature: ${data.temperature}\nDewpoint: ${data.dewpoint}\nHumidity: ${data.humidity}",
          platformChannelSpecifics,
          payload: 'daily');
    } catch (err) {
      await flip.show(0, "Error", "Temperature fetching error: $err",
          platformChannelSpecifics,
          payload: 'error');
    }
  }
}

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    FlutterLocalNotificationsPlugin flip = FlutterLocalNotificationsPlugin();
    var android = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var settings = InitializationSettings(android: android);

    await flip.initialize(settings);
    await NotificationService.showDailyNotification(flip);
    return true;
  });
}
