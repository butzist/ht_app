import 'package:firebase_database/firebase_database.dart';
import 'package:ht_app/services/SensorData.dart';
import 'package:tuple/tuple.dart';

abstract class HistoricalWeatherService {
  Future<List<Tuple2<DateTime, SensorData>>> queryHistory();
}

class FirebaseWeatherService implements HistoricalWeatherService {
  @override
  Future<List<Tuple2<DateTime, SensorData>>> queryHistory() async {
    final Query query =
        FirebaseDatabase.instance.ref("weather").orderByKey().limitToLast(24);

    snapshotToDouble(DataSnapshot snapshot) {
      var value = snapshot.value;
      if (value != null) {
        return value as double;
      }

      return double.nan;
    }

    var data = await query.get();
    if (data.exists) {
      var history = data.children
          .map((e) => Tuple2(
              DateTime.fromMillisecondsSinceEpoch(1000 * int.parse(e.key!)),
              SensorData(
                temperature: snapshotToDouble(e.child("t")),
              )))
          .toList();

      return history;
    }

    return [];
  }
}
