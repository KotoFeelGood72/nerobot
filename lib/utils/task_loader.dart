import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';

Future<List<Map<String, dynamic>>> loadTasks({
  required String role,
  required String currentFilter,
  DateTime? startDate,
  DateTime? endDate,
  double? minPrice,
  double? maxPrice,
  double? radiusKm,
  GeoPoint? userLocation,
}) async {
  Query query = FirebaseFirestore.instance.collection('orders');

  // --- БАЗОВЫЕ ФИЛЬТРЫ ---
  query = query
      .where('deleted', isEqualTo: false)
      .where('active', isEqualTo: true);

  // --- СТАТУС ---
  if (currentFilter == 'open') {
    query = query.where('status', isEqualTo: 'open');
  } else if (currentFilter == 'history') {
    query = query.where('status', whereIn: ['done', 'cancelled']);
  }

  // --- ФИЛЬТР ПО КООРДИНАТАМ ГОРОДА ДЛЯ ИСПОЛНИТЕЛЯ ---
  LatLng? userCityCoords;
  String? currentUserId;
  if (role == 'worker') {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    currentUserId = uid;

    if (uid != null) {
      final userSnap =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      final userData = userSnap.data();

      // Получаем координаты города пользователя
      if (userData != null) {
        final cityLat = userData['city_lat'];
        final cityLng = userData['city_lng'];

        if (cityLat != null && cityLng != null) {
          userCityCoords = LatLng(
            (cityLat is num)
                ? cityLat.toDouble()
                : double.tryParse(cityLat.toString()) ?? 0.0,
            (cityLng is num)
                ? cityLng.toDouble()
                : double.tryParse(cityLng.toString()) ?? 0.0,
          );
        }
      }
    }
  }

  // --- ЦЕНА ---
  if (minPrice != null) {
    query = query.where('price', isGreaterThanOrEqualTo: minPrice);
  }

  if (maxPrice != null) {
    query = query.where('price', isLessThanOrEqualTo: maxPrice);
  }

  // --- ДАТА ---
  if (startDate != null) {
    query = query.where(
      'created_date',
      isGreaterThanOrEqualTo: startDate.millisecondsSinceEpoch,
    );
  }

  if (endDate != null) {
    query = query.where(
      'created_date',
      isLessThanOrEqualTo: endDate.millisecondsSinceEpoch,
    );
  }

  query = query.orderBy('created_date', descending: true);

  final snapshot = await query.get();

  var tasks =
      snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();

  // Фильтрация по координатам города для исполнителя
  if (role == 'worker' && userCityCoords != null) {
    final distance = Distance();
    // Радиус для определения одного города (примерно 50 км)
    const cityRadiusMeters = 50000.0;

    tasks =
        tasks.where((task) {
          final taskLat = task['lat'];
          final taskLng = task['lng'];

          if (taskLat == null || taskLng == null) {
            return false;
          }

          final taskCoords = LatLng(
            (taskLat is num)
                ? taskLat.toDouble()
                : double.tryParse(taskLat.toString()) ?? 0.0,
            (taskLng is num)
                ? taskLng.toDouble()
                : double.tryParse(taskLng.toString()) ?? 0.0,
          );

          final distanceMeters = distance.as(
            LengthUnit.Meter,
            userCityCoords!,
            taskCoords,
          );

          return distanceMeters <= cityRadiusMeters;
        }).toList();
  }

  // Для вкладки "Открытые" у исполнителя показываем только задания, на которые он откликнулся
  if (role == 'worker' && currentFilter == 'open' && currentUserId != null) {
    tasks =
        tasks.where((task) {
          final responses = task['responses'];
          if (responses == null) return false;
          if (responses is! List) return false;
          return responses.contains(currentUserId);
        }).toList();
  }

  return tasks;
}
