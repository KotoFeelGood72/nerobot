import 'package:latlong2/latlong.dart';

import 'package:latlong2/latlong.dart';

class TaskDraft {
  String title;
  int price;
  DateTime date; // дата создания
  LatLng location;
  String address;
  String creatorUid;
  Duration executionTime; // ← убрали final, теперь mutable
  bool deleted;
  String? description;

  TaskDraft({
    required this.title,
    required this.price,
    required this.date,
    required this.location,
    required this.address,
    required this.creatorUid,
    required this.executionTime,
    required this.deleted,
    this.description,
  });

  Map<String, dynamic> toFirestoreMap() {
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    return {
      "title": title,
      "description": description ?? "",
      "price": price,
      "payment_for": "за смену",
      "lat": location.latitude,
      "lng": location.longitude,
      "address": address,
      "begin_at": date.millisecondsSinceEpoch,
      "execution_time": executionTime.inMilliseconds,
      "deleted": deleted,
      "created_date": createdAt,
      "creator": creatorUid,
      "active": true,
      "status": 'open',
    };
  }
}
