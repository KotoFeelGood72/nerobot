import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/firebase_options.dart';
import 'package:nerobot/router/app_router.dart';
import 'package:nerobot/themes/text_themes.dart';

final getIt = GetIt.instance;

/// 1. Фоновый хендлер — всегда должен быть top-level (не внутри класса)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Это будет вызвано, когда пуш придёт в фоне (app killed или background).
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📥 Получено фоновое сообщение: ${message.messageId}');
  // Здесь можно показать локальное уведомление или обработать данные.
}

/// 2. Локальный notifications-плагин (для отображения пушей в foreground)
final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// 3. Конфигурация для Android Notification Channel
const AndroidNotificationChannel _highImportanceChannel =
    AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'Этот канал используется для уведомлений высокой важности.',
      importance: Importance.high,
    );

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  getIt.registerSingleton<AppRouter>(AppRouter());
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('ru_RU', null);

  // 4. Регистрируем фоновый хендлер
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 5. Инициализируем локальный плагин
  if (Platform.isAndroid) {
    // Для Android: создаём канал до инициализации плагина
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_highImportanceChannel);
  }

  // 6. Настраиваем локальное уведомление (когда придёт пуш в foreground)
  const androidSettings = AndroidInitializationSettings(
    '@drawable/launcher_icon',
  );
  const iosSettings = DarwinInitializationSettings();
  final initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await _flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Эта коллбэк будет вызвана, когда пользователь тапнет на пуш (foreground)
      debugPrint('🖱 Notification tapped: ${response.payload}');
      // Здесь можно навигировать куда-то же в приложении
    },
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = getIt<AppRouter>();

    return MaterialApp.router(
      routerConfig: appRouter.config(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: MaterialColor(AppColors.violet.value, {
            50: AppColors.violet.withOpacity(0.1),
            100: AppColors.violet.withOpacity(0.2),
            200: AppColors.violet.withOpacity(0.3),
            300: AppColors.violet.withOpacity(0.4),
            400: AppColors.violet.withOpacity(0.5),
            500: AppColors.violet,
            600: AppColors.violet.withOpacity(0.7),
            700: AppColors.violet.withOpacity(0.8),
            800: AppColors.violet.withOpacity(0.9),
            900: AppColors.violet,
          }),
        ),
        primarySwatch: Colors.blue,
        textTheme: buildTextTheme(),
      ),
    );
  }
}
