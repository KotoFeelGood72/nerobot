import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:nerobot/utils/city_coordinates.dart';

const _activeStatuses = ['open', 'working', 'preview'];
const _historyStatuses = ['success', 'done', 'cancelled'];

/// Радиус «весь город» по умолчанию (км).
const defaultSearchRadiusKm = 50.0;

/// Максимальный радиус поиска в фильтрах (км).
const maxSearchRadiusKm = 200.0;

Future<List<Map<String, dynamic>>> loadTasks({
  required String role,
  required String currentFilter,
  DateTime? startDate,
  DateTime? endDate,
  double? minPrice,
  double? maxPrice,
  double? radiusKm,
  LatLng? userLocation,
  String? paymentFor,
  String? sortBy,
}) async {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  if (currentUserId == null) return [];

  LatLng? userCityCoords;

  if (role == 'worker') {
    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();
    final userData = userSnap.data();
    if (userData != null) {
      userCityCoords = _readCityCoords(userData);
      final cityName = userData['city'] ?? userData['selectedCity'];
      if (userCityCoords == null &&
          cityName is String &&
          cityName.isNotEmpty) {
        userCityCoords = CityCoordinates.getCityCoordinates(cityName);
      }
    }
  }

  // Простые запросы без composite-индексов: сортировка и доп. фильтры на клиенте.
  final docs = await _fetchOrderDocs(
    role: role,
    currentFilter: currentFilter,
    uid: currentUserId,
  );

  var tasks = docs
      .map((doc) => {...doc.data(), 'id': doc.id})
      .toList();

  tasks = tasks.where(_isVisibleOrder).toList();

  if (role == 'customer') {
    if (currentFilter == 'tasks') {
      tasks = tasks
          .where((t) => _activeStatuses.contains(t['status']?.toString()))
          .toList();
    } else if (currentFilter == 'history') {
      tasks = tasks
          .where((t) => _historyStatuses.contains(t['status']?.toString()))
          .toList();
    }
  }

  if (role == 'worker') {
    if (currentFilter == 'tasks') {
      // «Новые» — только open, на которые ещё не откликались
      tasks = tasks.where((t) {
        if (t['status']?.toString() != 'open') return false;
        if (_uidInList(t['responses'], currentUserId)) return false;
        if (_uidInList(t['workers'], currentUserId)) return false;
        return true;
      }).toList();
    } else if (currentFilter == 'open') {
      // Откликнулся или уже назначен исполнителем, заказ ещё активен
      tasks = tasks.where((task) {
        final status = task['status']?.toString();
        if (!_activeStatuses.contains(status)) return false;
        return _uidInList(task['responses'], currentUserId) ||
            _uidInList(task['workers'], currentUserId);
      }).toList();
    } else if (currentFilter == 'history') {
      tasks = tasks.where((task) {
        final status = task['status']?.toString();
        if (!_historyStatuses.contains(status)) return false;
        return _uidInList(task['workers'], currentUserId) ||
            _uidInList(task['responses'], currentUserId);
      }).toList();
    }
  }

  if (minPrice != null) {
    tasks = tasks.where((t) {
      final p = t['price'];
      final price = p is num ? p.toDouble() : double.tryParse('$p');
      return price != null && price >= minPrice;
    }).toList();
  }

  if (maxPrice != null) {
    tasks = tasks.where((t) {
      final p = t['price'];
      final price = p is num ? p.toDouble() : double.tryParse('$p');
      return price != null && price <= maxPrice;
    }).toList();
  }

  if (startDate != null) {
    final startMs = startDate.millisecondsSinceEpoch;
    tasks = tasks.where((t) {
      final created = t['created_date'];
      final ms = created is num ? created.toInt() : int.tryParse('$created') ?? 0;
      return ms >= startMs;
    }).toList();
  }

  if (endDate != null) {
    final endMs = endDate.millisecondsSinceEpoch;
    tasks = tasks.where((t) {
      final created = t['created_date'];
      final ms = created is num ? created.toInt() : int.tryParse('$created') ?? 0;
      return ms <= endMs;
    }).toList();
  }

  if (paymentFor != null && paymentFor.isNotEmpty) {
    final wanted = paymentFor.toLowerCase();
    tasks = tasks.where((t) {
      final raw = t['payment_for']?.toString().toLowerCase() ?? '';
      return raw == wanted;
    }).toList();
  }

  final filterCenter = userLocation ?? userCityCoords;
  final filterRadiusKm = radiusKm ?? defaultSearchRadiusKm;

  // Радиус применяем для ленты «Новые» у исполнителя.
  if (role == 'worker' &&
      currentFilter == 'tasks' &&
      filterCenter != null) {
    final before = tasks.length;
    tasks = filterTasksByRadius(
      tasks: tasks,
      center: filterCenter,
      radiusKm: filterRadiusKm,
    );

    debugPrint(
      'radius filter: center=${filterCenter.latitude},${filterCenter.longitude} '
      'r=${filterRadiusKm}km before=$before after=${tasks.length}',
    );
  }

  if (sortBy == 'По стоимости') {
    tasks.sort((a, b) {
      final ap = (a['price'] is num) ? (a['price'] as num).toDouble() : 0.0;
      final bp = (b['price'] is num) ? (b['price'] as num).toDouble() : 0.0;
      return ap.compareTo(bp);
    });
  } else {
    tasks.sort((a, b) {
      final ad = (a['created_date'] is num)
          ? (a['created_date'] as num).toInt()
          : 0;
      final bd = (b['created_date'] is num)
          ? (b['created_date'] as num).toInt()
          : 0;
      return bd.compareTo(ad);
    });
  }

  debugPrint(
    'loadTasks role=$role filter=$currentFilter count=${tasks.length}',
  );

  return tasks;
}

/// Минимальные запросы без composite index
/// (arrayContains / equality по одному полю — достаточно автоиндекса).
Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchOrderDocs({
  required String role,
  required String currentFilter,
  required String uid,
}) async {
  final orders = FirebaseFirestore.instance.collection('orders');

  if (role == 'customer') {
    final snap = await orders.where('creator', isEqualTo: uid).get();
    return snap.docs;
  }

  // worker
  if (currentFilter == 'tasks') {
    final snap = await orders.where('status', isEqualTo: 'open').get();
    return snap.docs;
  }

  if (currentFilter == 'open') {
    final byResponses = await orders
        .where('responses', arrayContains: uid)
        .get();
    final byWorkers =
        await orders.where('workers', arrayContains: uid).get();
    return _mergeDocs([byResponses.docs, byWorkers.docs]);
  }

  // history: заказы, где пользователь был исполнителем, + на всякий случай отклики
  final byWorkers =
      await orders.where('workers', arrayContains: uid).get();
  final byResponses =
      await orders.where('responses', arrayContains: uid).get();
  return _mergeDocs([byWorkers.docs, byResponses.docs]);
}

List<QueryDocumentSnapshot<Map<String, dynamic>>> _mergeDocs(
  List<List<QueryDocumentSnapshot<Map<String, dynamic>>>> groups,
) {
  final map = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
  for (final group in groups) {
    for (final doc in group) {
      map[doc.id] = doc;
    }
  }
  return map.values.toList();
}

bool _isVisibleOrder(Map<String, dynamic> task) {
  final deleted = task['deleted'];
  final active = task['active'];
  final isDeleted = deleted == true;
  final isActive = active == null ? true : active == true;
  return !isDeleted && isActive;
}

bool _uidInList(dynamic list, String uid) {
  if (list is! List) return false;
  return list.any((e) => e?.toString() == uid);
}

LatLng? _readCityCoords(Map<String, dynamic> userData) {
  final cityLat = userData['city_lat'];
  final cityLng = userData['city_lng'];
  if (cityLat == null || cityLng == null) return null;

  final lat = (cityLat is num)
      ? cityLat.toDouble()
      : double.tryParse(cityLat.toString());
  final lng = (cityLng is num)
      ? cityLng.toDouble()
      : double.tryParse(cityLng.toString());

  if (lat == null || lng == null) return null;
  if (latAbsInvalid(lat, lng)) return null;
  return LatLng(lat, lng);
}

LatLng? _readTaskCoords(Map<String, dynamic> task) {
  final taskLat = task['lat'];
  final taskLng = task['lng'];
  if (taskLat == null || taskLng == null) return null;

  final lat = (taskLat is num)
      ? taskLat.toDouble()
      : double.tryParse(taskLat.toString());
  final lng = (taskLng is num)
      ? taskLng.toDouble()
      : double.tryParse(taskLng.toString());

  if (lat == null || lng == null) return null;
  if (latAbsInvalid(lat, lng)) return null;
  return LatLng(lat, lng);
}

/// Фильтр по радиусу: координаты задачи, иначе центр её города.
/// Задачи без координат и без известного города отбрасываются.
@visibleForTesting
List<Map<String, dynamic>> filterTasksByRadius({
  required List<Map<String, dynamic>> tasks,
  required LatLng center,
  required double radiusKm,
}) {
  final distance = Distance();
  final radiusMeters = radiusKm * 1000;

  return tasks.where((task) {
    final taskCoords =
        _readTaskCoords(task) ??
        CityCoordinates.getCityCoordinates(task['city']?.toString() ?? '');
    if (taskCoords == null) return false;

    final distanceMeters = distance.as(
      LengthUnit.Meter,
      center,
      taskCoords,
    );
    return distanceMeters <= radiusMeters;
  }).toList();
}

bool latAbsInvalid(double lat, double lng) {
  if (lat == 0.0 && lng == 0.0) return true;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return true;
  return false;
}
