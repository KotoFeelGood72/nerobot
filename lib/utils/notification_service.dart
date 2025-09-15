import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Вызывайте этот метод один раз при старте приложения (например, в initState главного экрана)
  Future<void> initialize() async {
    // 1) Запрашиваем разрешения (особенно важно для iOS)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('NotificationSettings: $settings');

    // 2) Получаем FCM token (можно сохранить в Firestore, как мы делали раньше)
    String? token = await _messaging.getToken();
    debugPrint('📲 FCM Token: $token');

    // 3) Слушаем уведомления, когда приложение в foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 onMessage: ${message.messageId}');
      _showForegroundNotification(message);
    });

    // 4) Слушаем событие, когда пользователь тапнул по пушу и запустил приложение из background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🖱 onMessageOpenedApp: ${message.data}');
      // Навигируйте в нужную страницу, используя message.data
    });

    // 5) Если приложение было полностью закрыто (killed) и пуш на него кликнули
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('🔅 getInitialMessage: ${initialMessage.data}');
      // Навигируйте, если нужно
    }
  }

  /// Показывает локальное уведомление, когда пуш пришёл в foreground
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    // Извлекаем заголовок/тело
    final notification = message.notification;
    final android = message.notification?.android;
    if (notification == null || android == null) return;

    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel', // ID того же канала, что мы создали в main.dart
      'High Importance Notifications',
      channelDescription:
          'Этот канал используется для уведомлений высокой важности.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/launcher_icon',
    );

    final iosDetails = DarwinNotificationDetails();

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload:
          message.data['payload'] ??
          '', // если передавали данные в key="payload", достаём их
    );
  }
}
