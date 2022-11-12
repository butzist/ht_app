import 'package:firebase_database/firebase_database.dart';
import 'package:ht_app/services/LocalSensorService.dart';
import 'package:ht_app/services/SensorData.dart';

class FirebaseSensorService implements SensorService {
  FirebaseSensorService({required this.name});

  String name;

  @override
  Future<SensorData> query() async {
    final Query query = FirebaseDatabase.instance
        .ref("sensors/$name")
        .orderByKey()
        .limitToLast(1);

    var data = await query.get();
    if (data.exists) {
      var latest = data.children.first;

      return SensorData(
        temperature: latest.child("t").value as double,
        dewpoint: latest.child("d").value as double,
        humidity: latest.child("h").value as double,
      );
    }

    return const SensorData();
  }
}
