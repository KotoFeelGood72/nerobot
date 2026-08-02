import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:nerobot/utils/notification_constants.dart';

/// Сохранение FCM-токена и синхронизация топиков с настройками пользователя.
class PushTokenManager {
  static final _messaging = FirebaseMessaging.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> registerCurrentDevice() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final apns = await _messaging.getAPNSToken();
        if (apns == null) {
          debugPrint('⚠️ APNS token not ready, retry push registration later');
          return;
        }
      }

      final token = await _messaging.getToken();
      if (token == null) return;

      final userRef = _firestore.collection('users').doc(user.uid);
      await userRef.set({
        'device_tokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));

      final snap = await userRef.get();
      await syncTopicsFromUserData(snap.data());
      debugPrint('✅ FCM token saved and topics synced');
    } catch (e) {
      debugPrint('⚠️ PushTokenManager.registerCurrentDevice: $e');
    }
  }

  static Future<void> touchLastActive() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ touchLastActive: $e');
    }
  }

  static Future<void> syncTopicsFromUserData(Map<String, dynamic>? data) async {
    if (data == null) return;

    final prefs = Map<String, dynamic>.from(
      (data['notificationPreferences'] as Map<String, dynamic>?) ??
          NotificationPrefs.defaults,
    );
    final role = data['type'] as String? ?? 'worker';
    final city = (data['city'] ?? data['selectedCity'])?.toString() ?? '';

    final workerTopics = <String>{};
    if (role == 'worker') {
      if (prefs[NotificationPrefs.newTasks] == true) {
        workerTopics.add(NotificationTopics.newTasks);
      }
      if (prefs[NotificationPrefs.cityTask] == true && city.isNotEmpty) {
        workerTopics.add(NotificationTopics.cityTopicId(city));
      }
    }

    const allManagedTopics = <String>{
      NotificationTopics.newTasks,
    };

    for (final topic in allManagedTopics) {
      if (workerTopics.contains(topic)) {
        await _messaging.subscribeToTopic(topic);
      } else {
        await _messaging.unsubscribeFromTopic(topic);
      }
    }

    final storedCityTopic = data['subscribed_city_topic'] as String?;
    final nextCityTopic =
        role == 'worker' &&
                prefs[NotificationPrefs.cityTask] == true &&
                city.isNotEmpty
            ? NotificationTopics.cityTopicId(city)
            : null;

    if (storedCityTopic != null && storedCityTopic != nextCityTopic) {
      await _messaging.unsubscribeFromTopic(storedCityTopic);
    }
    if (nextCityTopic != null) {
      await _messaging.subscribeToTopic(nextCityTopic);
    }

    final uid = _auth.currentUser?.uid;
    if (uid != null && storedCityTopic != nextCityTopic) {
      await _firestore.collection('users').doc(uid).set({
        if (nextCityTopic != null) 'subscribed_city_topic': nextCityTopic,
        if (nextCityTopic == null)
          'subscribed_city_topic': FieldValue.delete(),
      }, SetOptions(merge: true));
    }
  }

  static Future<void> updatePreference({
    required String key,
    required bool enabled,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    await userRef.set({
      'notificationPreferences': {key: enabled},
    }, SetOptions(merge: true));

    final snap = await userRef.get();
    await syncTopicsFromUserData(snap.data());
  }

  static Future<Map<String, bool>> loadPreferences() async {
    final user = _auth.currentUser;
    if (user == null) return Map<String, bool>.from(NotificationPrefs.defaults);

    final snap = await _firestore.collection('users').doc(user.uid).get();
    final raw = snap.data()?['notificationPreferences'] as Map<String, dynamic>?;
    final result = Map<String, bool>.from(NotificationPrefs.defaults);
    raw?.forEach((key, value) {
      if (value is bool) result[key] = value;
    });
    return result;
  }

  /// Снимает topic-подписки и инвалидирует FCM-токен перед удалением аккаунта.
  static Future<void> clearLocalPushState({String? cityTopic}) async {
    try {
      await _messaging.unsubscribeFromTopic(NotificationTopics.newTasks);
      final topic = cityTopic?.trim();
      if (topic != null && topic.isNotEmpty) {
        await _messaging.unsubscribeFromTopic(topic);
      }
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('⚠️ clearLocalPushState: $e');
    }
  }
}
