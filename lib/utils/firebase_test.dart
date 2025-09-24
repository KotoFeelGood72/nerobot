import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseTest {
  static Future<void> testPhoneAuth() async {
    try {
      debugPrint('🔍 Тестируем Firebase Auth...');

      // Проверяем настройки
      final settings = FirebaseAuth.instance.app;
      debugPrint('✅ Firebase app: ${settings.name}');

      // Проверяем доступность Phone Auth
      final providers = await FirebaseAuth.instance.fetchSignInMethodsForEmail(
        'test@test.com',
      );
      debugPrint('✅ Auth providers доступны: $providers');

      // Тестируем отправку SMS на тестовый номер
      debugPrint('📱 Тестируем отправку SMS...');

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+7 999 123 45 67', // Тестовый номер
        timeout: const Duration(seconds: 10),
        verificationCompleted: (PhoneAuthCredential credential) {
          debugPrint('✅ Автопроверка прошла успешно');
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Ошибка проверки: ${e.code} - ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('✅ SMS отправлен, verificationId: $verificationId');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⏰ Таймаут автоподстановки кода');
        },
      );
    } catch (e) {
      debugPrint('❌ Ошибка тестирования Firebase Auth: $e');
    }
  }

  static void printFirebaseConfig() {
    debugPrint('🔧 Конфигурация Firebase:');
    debugPrint('Project ID: handy-35312');
    debugPrint('Package: com.handywork.app');
    debugPrint(
      'Debug SHA-1: C8:7C:BC:9C:C5:F4:72:2D:59:0C:3F:01:F7:93:DF:5C:33:DF:24:5D',
    );
    debugPrint(
      'Release SHA-1: 11:B9:54:2B:4E:29:8D:B5:BC:C5:BF:4D:B4:E2:60:6E:45:5C:88:62',
    );
    debugPrint(
      'Release SHA-256: 88:C3:32:BD:CF:F6:CF:B4:A5:A7:7F:60:C4:D7:79:41:61:F8:26:7B:0D:53:36:4E:CF:E7:A7:6F:0E:D7:F8:90',
    );
  }

  static Future<void> printCurrentFirebaseProject() async {
    try {
      final app = FirebaseAuth.instance.app;
      debugPrint('📱 Текущее Firebase приложение:');
      debugPrint('App name: ${app.name}');
      debugPrint('App options:');
      debugPrint('  - Project ID: ${app.options.projectId}');
      debugPrint('  - API Key: ${app.options.apiKey}');
      debugPrint('  - App ID: ${app.options.appId}');
      debugPrint('  - Messaging Sender ID: ${app.options.messagingSenderId}');
      debugPrint('  - Storage Bucket: ${app.options.storageBucket}');
      debugPrint('  - Auth Domain: ${app.options.authDomain}');

      // Проверяем настройки Auth
      debugPrint('🔐 Настройки Firebase Auth:');
      debugPrint(
        'Current user: ${FirebaseAuth.instance.currentUser?.uid ?? "Не авторизован"}',
      );
    } catch (e) {
      debugPrint('❌ Ошибка получения данных Firebase: $e');
    }
  }
}
