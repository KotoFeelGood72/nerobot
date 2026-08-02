import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.dart';
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/notification_constants.dart';
import 'package:nerobot/utils/push_token_manager.dart';
import 'package:nerobot/utils/root_scaffold_messenger.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Future<void>? _initFuture;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;
  OverlayEntry? _bannerEntry;
  int _localId = 0;

  Future<void> initialize() {
    _initFuture ??= _doInitialize();
    return _initFuture!;
  }

  Future<void> _doInitialize() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@drawable/ic_stat_notification');
    const ios = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    await _createAndroidChannel();
    await _requestPermissions();

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _onMessageSub?.cancel();
    await _onOpenedSub?.cancel();

    _onMessageSub = FirebaseMessaging.onMessage.listen(
      (message) {
        debugPrint(
          '📨 onMessage id=${message.messageId} '
          'title=${message.notification?.title} data=${message.data}',
        );
        unawaited(_handleForegroundMessage(message));
      },
      onError: (Object e) => debugPrint('❌ onMessage error: $e'),
    );

    _onOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleNotificationTap,
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _scheduleNavigation(initialMessage.data);
    }

    _messaging.onTokenRefresh.listen((_) async {
      await PushTokenManager.registerCurrentDevice();
    });

    await PushTokenManager.registerCurrentDevice();
    await PushTokenManager.touchLastActive();

    _initialized = true;
    debugPrint('✅ NotificationService ready');
  }

  Future<void> _createAndroidChannel() async {
    if (!Platform.isAndroid) return;

    final androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    // Старый канал с низкой importance Android не обновляет — удаляем.
    await androidPlugin?.deleteNotificationChannel('high_importance_channel');

    const channel = AndroidNotificationChannel(
      NotificationChannels.highImportanceId,
      NotificationChannels.highImportanceName,
      description: NotificationChannels.highImportanceDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Notification permission: ${settings.authorizationStatus}');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title =
        notification?.title ??
        message.data['title']?.toString() ??
        'Уведомление';
    final body =
        notification?.body ??
        message.data['body']?.toString() ??
        'Новое событие в приложении';

    // 1) Системное уведомление через flutter_local_notifications
    await _showSystemNotification(title, body, message);

    // 2) Баннер внутри приложения — дублирует, если ОС скрывает heads-up
    _showInAppBanner(title, body, message.data);
  }

  Future<void> _showSystemNotification(
    String title,
    String body,
    RemoteMessage message,
  ) async {
    final androidDetails = AndroidNotificationDetails(
      NotificationChannels.highImportanceId,
      NotificationChannels.highImportanceName,
      channelDescription: NotificationChannels.highImportanceDescription,
      importance: Importance.max,
      priority: Priority.max,
      // Маленькая иконка в статус-баре: только белая silhouette
      icon: '@drawable/ic_stat_notification',
      // Большая цветная иконка приложения в шторке
      largeIcon: const DrawableResourceAndroidBitmap('ic_launcher'),
      color: AppColors.violet,
      colorized: false,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.message,
      ticker: title,
      channelShowBadge: true,
      autoCancel: true,
      onlyAlertOnce: false,
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Разнорабочий',
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    try {
      _localId = (_localId + 1) % 100000;
      await _localNotifications.show(
        _localId,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        payload: message.data['type']?.toString() ?? '',
      );
      debugPrint('✅ System local notification queued: $title');
    } catch (e, st) {
      debugPrint('❌ System notification failed: $e\n$st');
    }
  }

  void _showInAppBanner(
    String title,
    String body,
    Map<String, dynamic> data,
  ) {
    // 1) Overlay поверх текущего navigator (предпочтительно)
    final overlay = GetIt.I<AppRouter>().navigatorKey.currentState?.overlay;
    if (overlay != null) {
      _insertOverlayBanner(overlay, title, body, data);
      return;
    }

    // 2) MaterialBanner через глобальный ScaffoldMessenger
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger != null) {
      messenger.clearMaterialBanners();
      messenger.showMaterialBanner(
        MaterialBanner(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/app-icon.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.notifications_active,
                color: AppColors.violet,
              ),
            ),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(body, style: const TextStyle(fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                messenger.hideCurrentMaterialBanner();
                _navigateFromData(data);
              },
              child: const Text('Открыть'),
            ),
            TextButton(
              onPressed: messenger.hideCurrentMaterialBanner,
              child: const Text('Закрыть'),
            ),
          ],
        ),
      );
      debugPrint('✅ In-app MaterialBanner shown: $title');
      Future<void>.delayed(const Duration(seconds: 5), () {
        messenger.hideCurrentMaterialBanner();
      });
      return;
    }

    debugPrint('⚠️ No Overlay/ScaffoldMessenger for in-app banner');
  }

  void _insertOverlayBanner(
    OverlayState overlay,
    String title,
    String body,
    Map<String, dynamic> data,
  ) {
    _bannerEntry?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        final top = MediaQuery.paddingOf(ctx).top + 8;
        return Positioned(
          top: top,
          left: 12,
          right: 12,
          child: Material(
            elevation: 10,
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            shadowColor: Colors.black54,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                entry.remove();
                if (_bannerEntry == entry) _bannerEntry = null;
                _navigateFromData(data);
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/app-icon.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.violet.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.notifications_active,
                            color: AppColors.violet,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            body,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.gray,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        entry.remove();
                        if (_bannerEntry == entry) _bannerEntry = null;
                      },
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    _bannerEntry = entry;
    overlay.insert(entry);
    debugPrint('✅ In-app overlay banner shown: $title');

    Future<void>.delayed(const Duration(seconds: 5), () {
      if (_bannerEntry == entry) {
        entry.remove();
        _bannerEntry = null;
      }
    });
  }

  void _handleNotificationTap(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  void _scheduleNavigation(Map<String, dynamic> data) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateFromData(data);
    });
  }

  void _navigateFromData(Map<String, dynamic> data) {
    final router = GetIt.I<AppRouter>();
    final type = data['type']?.toString();
    final orderId = data['orderId']?.toString();
    final chatId = data['chatId']?.toString();

    switch (type) {
      case 'chat_message':
        if (chatId == null || chatId.isEmpty) return;
        router.push(ChatsRoute(chatsId: chatId, taskId: orderId ?? ''));
        return;
      case 'order_response':
        if (orderId == null || orderId.isEmpty) return;
        router.push(TaskDetailCustomerRoute(taskId: orderId));
        return;
      case 'new_task':
        if (orderId != null && orderId.isNotEmpty) {
          router.push(TaskDetailRoute(taskId: orderId));
        } else {
          router.push(const TaskRoute());
        }
        return;
      case 'inactive_reminder':
        router.push(const TaskRoute());
        return;
      default:
        return;
    }
  }
}
