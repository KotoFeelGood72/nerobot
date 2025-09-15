import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String status; // 'pending', 'completed', 'failed', 'refunded'
  final String paymentMethod; // 'card', 'sbp', 'other'
  final String? description;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? transactionId;
  final String? subscriptionType; // 'monthly', 'quarterly', 'yearly'
  final int? subscriptionPeriod; // количество месяцев

  Payment({
    required this.id,
    required this.userId,
    required this.amount,
    this.currency = 'RUB',
    required this.status,
    required this.paymentMethod,
    this.description,
    required this.createdAt,
    this.completedAt,
    this.transactionId,
    this.subscriptionType,
    this.subscriptionPeriod,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'paymentMethod': paymentMethod,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'transactionId': transactionId,
      'subscriptionType': subscriptionType,
      'subscriptionPeriod': subscriptionPeriod,
    };
  }

  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Payment(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'RUB',
      status: data['status'] ?? 'pending',
      paymentMethod: data['paymentMethod'] ?? 'card',
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null,
      transactionId: data['transactionId'],
      subscriptionType: data['subscriptionType'],
      subscriptionPeriod: data['subscriptionPeriod'],
    );
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'В обработке';
      case 'completed':
        return 'Оплачено';
      case 'failed':
        return 'Ошибка';
      case 'refunded':
        return 'Возврат';
      default:
        return 'Неизвестно';
    }
  }

  String get paymentMethodText {
    switch (paymentMethod) {
      case 'card':
        return 'Банковская карта';
      case 'sbp':
        return 'СБП';
      default:
        return 'Другой способ';
    }
  }

  String get formattedAmount => '$amount $currency';
}





