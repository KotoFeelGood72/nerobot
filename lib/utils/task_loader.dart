// task_loader.dart

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  print('=== ВЫЗОВ loadTasks ===');
  print('role: $role');
  print('currentFilter: $currentFilter');
  print('minPrice: $minPrice');
  print('maxPrice: $maxPrice');
  print('radiusKm: $radiusKm');
  print('userLocation: $userLocation');
  if (userLocation != null) {
    print('Координаты в loadTasks: ${userLocation.latitude}, ${userLocation.longitude}');
  }
  
  final uid = FirebaseAuth.instance.currentUser!.uid;
  late Query<Map<String, dynamic>> q;

  if (role == 'worker') {
    switch (currentFilter) {
      case 'open':
        q = FirebaseFirestore.instance
            .collection('orders')
            .where('status', whereIn: ['open', 'preview', 'working'])
            .where('responses', arrayContains: uid);
        break;
      case 'history':
        q = FirebaseFirestore.instance
            .collection('orders')
            .where('active', isEqualTo: true)
            .where('status', isEqualTo: 'success');
        break;
      default:
        q = FirebaseFirestore.instance
            .collection('orders')
            .where('active', isEqualTo: true)
            .where('deleted', isEqualTo: false)
            .where('status', whereNotIn: ['working', 'success', 'preview']);
    }
  } else {
    if (currentFilter == 'history') {
      q = FirebaseFirestore.instance
          .collection('orders')
          .where('creator', isEqualTo: uid)
          .where('status', isEqualTo: 'success');
    } else {
      q = FirebaseFirestore.instance
          .collection('orders')
          .where('creator', isEqualTo: uid);
    }
  }

  final snap = await q.get();
  var data = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  
  print('Получено задач из Firestore: ${data.length}');
  print('Первые 3 задачи:');
  for (int i = 0; i < data.length && i < 3; i++) {
    final task = data[i];
    print('  Задача ${task['id']}: lat=${task['lat']}, lng=${task['lng']}');
  }

  if (role == 'worker' && currentFilter == 'tasks') {
    data =
        data.where((t) {
          final List resps = (t['responses'] ?? []) as List;
          return !resps.contains(uid);
        }).toList();
  }

  if (userLocation != null && radiusKm != null) {
    print('=== ФИЛЬТРАЦИЯ ПО РАССТОЯНИЮ ===');
    print('Радиус: $radiusKm км');
    print('Координаты пользователя: ${userLocation.latitude}, ${userLocation.longitude}');
    
    final beforeCount = data.length;
    data =
        data.where((t) {
          // Проверяем поля lat и lng (как в Firestore)
          final lat = t['lat'];
          final lng = t['lng'];

          if (lat == null || lng == null) {
            print('  Задача ${t['id']}: координаты отсутствуют (lat=$lat, lng=$lng)');
            return false;
          }

          final taskLat =
              (lat is int)
                  ? lat.toDouble()
                  : (lat is double)
                  ? lat
                  : 0.0;
          final taskLng =
              (lng is int)
                  ? lng.toDouble()
                  : (lng is double)
                  ? lng
                  : 0.0;

          if (taskLat == 0.0 || taskLng == 0.0) {
            print('  Задача ${t['id']}: неверные координаты (lat=$taskLat, lng=$taskLng)');
            return false;
          }

          final d = _distanceKm(
            userLocation.latitude,
            userLocation.longitude,
            taskLat,
            taskLng,
          );

          final isInRadius = d <= radiusKm;
          print(
            '  Задача ${t['id']}: расстояние ${d.toStringAsFixed(2)} км (радиус: $radiusKm км) - ${isInRadius ? "✅ В РАДИУСЕ" : "❌ ВНЕ РАДИУСА"}',
          );
          return isInRadius;
        }).toList();
    
    final afterCount = data.length;
    print('Результат фильтрации: $beforeCount → $afterCount задач');
    print('========================');
  } else {
    print('⚠️ Фильтрация по расстоянию пропущена: userLocation=${userLocation != null}, radiusKm=${radiusKm != null}');
  }

  if (minPrice != null || maxPrice != null) {
    data =
        data.where((t) {
          final price = (t['price'] ?? 0).toDouble();
          if (minPrice != null && price < minPrice) return false;
          if (maxPrice != null && price > maxPrice) return false;
          return true;
        }).toList();
  }

  if (startDate != null || endDate != null) {
    data =
        data.where((t) {
          final ts = t['date'];
          if (ts is! Timestamp) return false;
          final dt = ts.toDate();
          if (startDate != null && dt.isBefore(startDate)) return false;
          if (endDate != null && dt.isAfter(endDate)) return false;
          return true;
        }).toList();
  }

  return data;
}

double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const double R = 6371;
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);
  final a =
      (sin(dLat / 2) * sin(dLat / 2)) +
      cos(_deg2rad(lat1)) *
          cos(_deg2rad(lat2)) *
          (sin(dLon / 2) * sin(dLon / 2));
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

double _deg2rad(double deg) => deg * (3.14159265359 / 180);
