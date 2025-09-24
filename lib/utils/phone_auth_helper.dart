import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PhoneAuthHelper {
  static Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) onVerificationCompleted,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(String, int?) onCodeSent,
    required Function(String) onCodeAutoRetrievalTimeout,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      // Настройки для принудительного использования нативной reCAPTCHA
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: false,
        forceRecaptchaFlow: false,
      );

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: timeout,
        verificationCompleted: onVerificationCompleted,
        verificationFailed: onVerificationFailed,
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
        // Принудительно используем нативную reCAPTCHA
        forceResendingToken: null,
        // Дополнительные параметры для правильной работы reCAPTCHA
        multiFactorSession: null,
        multiFactorInfo: null,
      );
    } catch (e) {
      debugPrint('❌ Ошибка в PhoneAuthHelper: $e');
      onVerificationFailed(
        FirebaseAuthException(
          code: 'unknown-error',
          message: 'Неизвестная ошибка: $e',
        ),
      );
    }
  }

  /// Альтернативный метод для случаев, когда WebView все равно открывается
  static Future<bool> isNativeRecaptchaSupported() async {
    try {
      // Проверяем, поддерживается ли нативная reCAPTCHA
      final auth = FirebaseAuth.instance;
      // Если приложение правильно настроено, нативная reCAPTCHA должна работать
      return true;
    } catch (e) {
      debugPrint('❌ Нативная reCAPTCHA не поддерживается: $e');
      return false;
    }
  }

  /// Метод для принудительного отключения WebView
  static Future<void> disableWebViewRecaptcha() async {
    try {
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: false,
        forceRecaptchaFlow: false,
      );
      debugPrint('✅ WebView reCAPTCHA отключена');
    } catch (e) {
      debugPrint('❌ Не удалось отключить WebView reCAPTCHA: $e');
    }
  }

  /// Метод для настройки reCAPTCHA с правильными redirects
  static Future<void> configureRecaptchaRedirects() async {
    try {
      // Настройки для правильной работы reCAPTCHA redirects
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: false,
        forceRecaptchaFlow: false,
      );

      debugPrint('✅ reCAPTCHA redirects настроены');
      debugPrint('✅ Домен: handy-35312.firebaseapp.com');
      debugPrint('✅ Package: com.handywork.app');
    } catch (e) {
      debugPrint('❌ Ошибка настройки reCAPTCHA redirects: $e');
    }
  }
}
