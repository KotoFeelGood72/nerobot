import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nerobot/models/subscription.dart';

class SubscriptionUtils {
  static final _db = FirebaseFirestore.instance;

  /// 🔥 ГЛАВНАЯ ФУНКЦИЯ — гарантирует триал
  static Future<void> ensureFreeTrial(String userId) async {
    final uid = userId.trim();

    try {
      final active = await getActiveSubscription(uid);
      if (active != null) {
        debugPrint('ℹ️ Active subscription already exists');
        return;
      }

      await _createTrial(uid);
      await _syncUserSubscription(uid);

      debugPrint('✅ Trial subscription granted for $uid');
    } catch (e, st) {
      debugPrint('❌ ensureFreeTrial ERROR: $e\n$st');
    }
  }

  /// 🔍 Проверка активной подписки
  static Future<Subscription?> getActiveSubscription(String userId) async {
    try {
      final snap = await _db
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      if (snap.docs.isEmpty) return null;

      return Subscription.fromFirestore(snap.docs.first);
    } catch (e) {
      debugPrint('❌ getActiveSubscription ERROR: $e');
      return null;
    }
  }

  /// 🆓 Создание триала
  static Future<void> _createTrial(String userId) async {
    final now = DateTime.now();
    final end = now.add(const Duration(days: 90));

    final sub = Subscription(
      id: userId,
      userId: userId,
      type: 'trial',
      period: 3,
      startDate: now,
      endDate: end,
      status: 'active',
      amount: 0,
      paymentId: '',
    );

    await _db
        .collection('subscriptions')
        .doc(userId)
        .set(sub.toFirestore());

    debugPrint('✅ Trial subscription created');
  }

  /// 🔄 СИНХРОНИЗАЦИЯ USERS ← SUBSCRIPTIONS (ЭТОГО У ТЕБЯ НЕ БЫЛО)
  static Future<void> _syncUserSubscription(String userId) async {
    await _db.collection('users').doc(userId).set({
      'subscription_status': true,
      'subscription_type': 'trial',
      'subscription_days': 90,
    }, SetOptions(merge: true));

    debugPrint('✅ User subscription synced');
  }

  // ==========================================================
  // ⬇️⬇️⬇️ ЧТОБЫ НЕ ПАДАЛ БИЛД (старые вызовы экранов)
  // ==========================================================

  static Future<String> createSubscription(Subscription s) async {
    final ref = await _db.collection('subscriptions').add(s.toFirestore());
    return ref.id;
  }

  static Future<void> updateSubscriptionStatus(
    String id,
    String status,
  ) async {
    await _db.collection('subscriptions').doc(id).update({
      'status': status,
    });
  }
}
