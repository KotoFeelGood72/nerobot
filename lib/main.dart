import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'utils/firebase_initializer.dart';
import 'utils/firebase_auth_config.dart';
import 'services/user_service.dart';
import 'utils/subscription_utils.dart';
import 'router/app_router.dart';
import 'constants/app_colors.dart';
import 'constants/env.dart';
import 'themes/text_themes.dart';
import 'firebase_options.dart';

final getIt = GetIt.instance;
final _ln = FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Each background isolate may require its own Firebase initialization.
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    //ignore
  }
  debugPrint('📩 Background push: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // detect if this is a background/isolate entrypoint created by a plugin
  final String initialRoute = PlatformDispatcher.instance.defaultRouteName;
  final bool isBackgroundIsolate = initialRoute != '/' && initialRoute.isNotEmpty;

  if (!isBackgroundIsolate) {
    await FirebaseInitializer.initialize();
    // Эмуляторы: симулятор — localhost; физическое устройство — IP Mac (телефон и Mac в одной Wi‑Fi).
    // Симулятор: flutter run --dart-define=USE_EMULATORS=true
    // Устройство: flutter run --dart-define=USE_EMULATORS=true --dart-define=EMULATOR_HOST=192.168.x.x
    // На Mac: firebase emulators:start --only auth,firestore --host 0.0.0.0
    const bool _useEmulators = bool.fromEnvironment('USE_EMULATORS', defaultValue: false);
    const String _emulatorHost = String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');
    if (_useEmulators) {
      await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 8080);
      debugPrint('🔧 Emulators: Auth + Firestore at $_emulatorHost:9099 / $_emulatorHost:8080');
    } else {
      debugPrint('🔧 Real Firebase (device/production)');
    }
  } else {
    debugPrint('Main skipped Firebase initialization because this is a background isolate. route=$initialRoute');
  }

  getIt.registerSingleton<AppRouter>(AppRouter());

  // App Check: отключить для теста Phone Auth (network-request-failed). Если без него заработает — зарегистрируй debug-токен в Firebase Console → App Check → Manage debug tokens.
  const bool _skipAppCheckForAuthTest = true; // верни false и зарегистрируй токен перед продакшеном
  if (!_skipAppCheckForAuthTest) {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
      debugPrint("🛡 AppCheck activated");
    } catch (e) {
      debugPrint("❌ AppCheck error: $e");
    }
  } else {
    debugPrint("🛡 AppCheck skipped (auth test mode)");
  }

  if (const bool.fromEnvironment('FORCE_PHONE_AUTH_TESTING', defaultValue: false) ||
      forcePhoneAuthTestingMode) {
    FirebaseAuthConfig.configureForTesting();
    if (kDebugMode) debugPrint('📱 Phone Auth: testing mode (только тестовые номера из Firebase Console)');
  } else {
    FirebaseAuthConfig.configureForProduction();
  }
  await initializeDateFormatting('ru_RU');

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await _ln.initialize(const InitializationSettings(android: android, iOS: ios));

  // Listen for auth changes and ensure user doc + trial subscription
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    debugPrint("ℹ️ authStateChanges: user == ${user?.uid}");
    if (user != null) {
      final ok = await UserService.createUserIfNotExists(user, "user");
      if (ok) {
        // ensure trial - note: this will attempt Firestore access; may fail if offline/block
        try {
          await SubscriptionUtils.ensureFreeTrial(user.uid);
        } catch (e) {
          debugPrint('⚠️ ensureFreeTrial failed: $e');
        }
      }
    }
  });

  // Debug helpers: print Firebase info and try a simple write (non-invasive)
  // Run only in main engine
  if (!isBackgroundIsolate) {
    debugFirebaseInfo();
    await testConnectFirestore();
  }

  runApp(const MyApp());
}

/// Debug: print Firebase apps info
void debugFirebaseInfo() {
  try {
    for (final app in Firebase.apps) {
      final opts = app.options;
      debugPrint('FIREBASE APP name=${app.name} projectId=${opts.projectId} appId=${opts.appId} apiKey=${opts.apiKey}');
    }
    debugPrint('Firestore instance: ${FirebaseFirestore.instance}');
  } catch (e) {
    debugPrint('debugFirebaseInfo ERROR: $e');
  }
}

/// Debug: simple write/read to verify Firestore connectivity (только если пользователь уже залогинен)
Future<void> testConnectFirestore() async {
  try {
    if (FirebaseAuth.instance.currentUser == null) {
      debugPrint('TEST FIRESTORE: skip (not signed in, rules require auth)');
      return;
    }
    final docRef = FirebaseFirestore.instance.collection('debug_connect').doc('ping');
    await docRef.set({'ts': FieldValue.serverTimestamp()});
    final snap = await docRef.get();
    debugPrint('TEST FIRESTORE OK: exists=${snap.exists} data=${snap.data()}');
  } on FirebaseException catch (e) {
    debugPrint('TEST FIRESTORE FIREBASE ERROR: code=${e.code} message=${e.message}');
  } catch (e, st) {
    debugPrint('TEST FIRESTORE ERROR: $e\n$st');
  }
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
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: buildTextTheme(),
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
      ),
    );
  }
}