import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:nerobot/models/payment.dart';

class PaymentUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получает все платежи пользователя
  static Future<List<Payment>> getUserPayments(String userId) async {
    final querySnapshot =
        await _firestore
            .collection('payments')
            .where('userId', isEqualTo: userId)
            .get();

    final payments =
        querySnapshot.docs.map((doc) => Payment.fromFirestore(doc)).toList();

    // Сортировка по дате создания (новые сначала)
    payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return payments;
  }

  /// Создает новый платеж
  static Future<String> createPayment(Payment payment) async {
    final docRef = await _firestore
        .collection('payments')
        .add(payment.toFirestore());
    return docRef.id;
  }

  /// Обновляет статус платежа
  static Future<void> updatePaymentStatus(
    String paymentId,
    String status,
  ) async {
    await _firestore.collection('payments').doc(paymentId).update({
      'status': status,
      if (status == 'completed') 'completedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Получает статистику платежей пользователя
  static Future<Map<String, dynamic>> getPaymentStats(String userId) async {
    final payments = await getUserPayments(userId);

    double totalAmount = 0;
    int completedCount = 0;
    int pendingCount = 0;
    int failedCount = 0;

    for (final payment in payments) {
      totalAmount += payment.amount;
      switch (payment.status) {
        case 'completed':
          completedCount++;
          break;
        case 'pending':
          pendingCount++;
          break;
        case 'failed':
          failedCount++;
          break;
      }
    }

    return {
      'totalAmount': totalAmount,
      'totalCount': payments.length,
      'completedCount': completedCount,
      'pendingCount': pendingCount,
      'failedCount': failedCount,
    };
  }
}
