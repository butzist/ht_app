import 'package:firebase_database/firebase_database.dart';

class FirebaseAnnotationService {
  Future<void> setFogLevel(int fogLevel) async {
    var currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var db = FirebaseDatabase.instance.ref("annotations/$currentTime");
    await db.set({"fogLevel": fogLevel});
  }
}
