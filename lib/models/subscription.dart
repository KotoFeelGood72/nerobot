import 'package:cloud_firestore/cloud_firestore.dart';

class Subscription {
  final String id;
  final String userId;
  final String type; // 'monthly', 'quarterly', 'yearly'
  final int period; // количество месяцев
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'active', 'expired', 'cancelled'
  final double amount;
  final String paymentId; // ссылка на платеж

  Subscription({
    required this.id,
    required this.userId,
    required this.type,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.amount,
    required this.paymentId,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'period': period,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'status': status,
      'amount': amount,
      'paymentId': paymentId,
    };
  }

  factory Subscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subscription(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'monthly',
      period: data['period'] ?? 1,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'active',
      amount: (data['amount'] ?? 0).toDouble(),
      paymentId: data['paymentId'] ?? '',
    );
  }

  bool get isActive => status == 'active' && DateTime.now().isBefore(endDate);

  Duration get remainingTime => endDate.difference(DateTime.now());

  String get remainingTimeText {
    if (status == 'cancelled') return 'Отменена';
    if (!isActive) return 'Истекла';

    final days = remainingTime.inDays;
    final months = days ~/ 30;
    final remainingDays = days % 30;

    if (months > 0) {
      if (remainingDays > 0) {
        return '$months мес $remainingDays дн';
      } else {
        return '$months мес';
      }
    } else {
      return '$days дн';
    }
  }

  String get typeText {
    switch (type) {
      case 'monthly':
        return 'Месячная';
      case 'quarterly':
        return 'Квартальная';
      case 'yearly':
        return 'Годовая';
      case 'trial':
        return 'Пробная';
      default:
        return 'Пользовательская';
    }
  }
}
