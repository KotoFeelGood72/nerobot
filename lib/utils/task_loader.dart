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

  if (role == 'worker' && currentFilter == 'tasks') {
    data =
        data.where((t) {
          final List resps = (t['responses'] ?? []) as List;
          return !resps.contains(uid);
        }).toList();
  }

  if (userLocation != null && radiusKm != null) {
    data =
        data.where((t) {
          final loc = t['location'];
          if (loc is! GeoPoint) return false;
          final d = _distanceKm(
            userLocation.latitude,
            userLocation.longitude,
            loc.latitude,
            loc.longitude,
          );
          return d <= radiusKm;
        }).toList();
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
