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

  // --- ФИЛЬТР ПО ГОРОДУ ДЛЯ ИСПОЛНИТЕЛЯ ---
  if (role == 'worker') {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final city = userSnap.data()?['city'];

      if (city != null && city.toString().isNotEmpty) {
        query = query.where('city', isEqualTo: city);
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

  return snapshot.docs
      .map((doc) => {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          })
      .toList();
}
