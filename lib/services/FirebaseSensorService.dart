import 'package:firebase_database/firebase_database.dart';
import 'package:ht_app/services/LocalSensorService.dart';
import 'package:ht_app/services/SensorData.dart';
import 'package:tuple/tuple.dart';

class FirebaseSensorService implements SensorService {
  FirebaseSensorService({required this.name});

  String name;

  @override
  Future<SensorData> queryCurrent() async {
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

  @override
  Future<List<Tuple2<DateTime, SensorData>>> queryHistory() async {
    final Query query = FirebaseDatabase.instance
        .ref("sensors/$name")
        .orderByKey()
        .limitToLast((60 ~/ 10) * 24);

    var data = await query.get();
    if (data.exists) {
      var history = data.children
          .map((e) => Tuple2(
              DateTime.fromMillisecondsSinceEpoch(1000 * int.parse(e.key!)),
              SensorData(
                temperature: e.child("t").value as double,
                dewpoint: e.child("d").value as double,
                humidity: e.child("h").value as double,
              )))
          .toList();

      return history;
    }

    return [];
  }
}
