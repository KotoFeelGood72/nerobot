import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nerobot/models/subscription.dart';

class SubscriptionUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получает активную подписку пользователя
  static Future<Subscription?> getActiveSubscription(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .get(const GetOptions(source: Source.server));

      if (querySnapshot.docs.isEmpty) return null;

      // Сортируем по дате окончания (новые сначала) и берем первую
      final subscriptions =
          querySnapshot.docs
              .map((doc) => Subscription.fromFirestore(doc))
              .toList()
            ..sort((a, b) => b.endDate.compareTo(a.endDate));

      print('DEBUG: Найдено подписок: ${subscriptions.length}');
      print(
        'DEBUG: Статусы подписок: ${subscriptions.map((s) => s.status).toList()}',
      );

      // Фильтруем только активные подписки (не отмененные)
      final activeSubscriptions =
          subscriptions.where((s) => s.status != 'cancelled').toList();

      print(
        'DEBUG: Активных подписок после фильтрации: ${activeSubscriptions.length}',
      );

      if (activeSubscriptions.isEmpty) return null;

      final subscription = activeSubscriptions.first;
      print('DEBUG: Возвращаем подписку со статусом: ${subscription.status}');

      // Проверяем, что подписка действительно активна (не истекла)
      if (subscription.isActive) {
        return subscription;
      } else {
        // Если подписка истекла, обновляем её статус
        await _firestore
            .collection('subscriptions')
            .doc(subscription.id)
            .update({'status': 'expired'});
        return null;
      }
    } catch (e) {
      print('Ошибка при получении активной подписки: $e');
      return null;
    }
  }

  /// Создает новую подписку
  static Future<String> createSubscription(Subscription subscription) async {
    final docRef = await _firestore
        .collection('subscriptions')
        .add(subscription.toFirestore());
    return docRef.id;
  }

  /// Создает бесплатную подписку на 1 месяц для нового пользователя
  static Future<String> createFreeTrialSubscription(String userId) async {
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 30)); // 1 месяц

    final subscription = Subscription(
      id: '',
      userId: userId,
      type: 'trial',
      period: 1,
      startDate: now,
      endDate: endDate,
      status: 'active',
      amount: 0.0,
      paymentId: '', // Пустая строка для бесплатной подписки
    );

    final docRef = await _firestore
        .collection('subscriptions')
        .add(subscription.toFirestore());

    print('DEBUG: Создана бесплатная подписка для пользователя $userId');
    return docRef.id;
  }

  /// Обновляет статус подписки
  static Future<void> updateSubscriptionStatus(
    String subscriptionId,
    String status,
  ) async {
    print('DEBUG: Обновляем статус подписки $subscriptionId на $status');

    await _firestore.collection('subscriptions').doc(subscriptionId).update({
      'status': status,
    });

    print('DEBUG: Статус подписки успешно обновлен');

    // Небольшая задержка для обработки изменений в Firestore
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Получает все подписки пользователя
  static Future<List<Subscription>> getUserSubscriptions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .get(const GetOptions(source: Source.server));

      final subscriptions =
          querySnapshot.docs
              .map((doc) => Subscription.fromFirestore(doc))
              .toList();

      // Сортировка по дате начала (новые сначала)
      subscriptions.sort((a, b) => b.startDate.compareTo(a.startDate));

      return subscriptions;
    } catch (e) {
      print('Ошибка при получении подписок пользователя: $e');
      return [];
    }
  }

  /// Создает тестовую подписку
  static Future<void> createTestSubscription(String userId) async {
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 90)); // 3 месяца

    final subscription = Subscription(
      id: '',
      userId: userId,
      type: 'quarterly',
      period: 3,
      startDate: now,
      endDate: endDate,
      status: 'active',
      amount: 699.0,
      paymentId: 'test_payment_id',
    );

    await createSubscription(subscription);
  }

  /// Проверяет, есть ли у пользователя активная подписка
  static Future<bool> hasActiveSubscription(String userId) async {
    final subscription = await getActiveSubscription(userId);
    return subscription != null && subscription.isActive;
  }
}
