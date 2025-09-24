import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthConfig {
  static void configureForNativeRecaptcha() {
    // Настройки для принудительного использования нативной reCAPTCHA
    FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: false, // Включаем для продакшена
      forceRecaptchaFlow: false, // Отключаем принудительный reCAPTCHA flow
    );
  }

  static void configureForTesting() {
    // Настройки для тестирования (отключаем reCAPTCHA полностью)
    FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
      forceRecaptchaFlow: false,
    );
  }

  static void configureForProduction() {
    // Настройки для продакшена
    FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: false,
      forceRecaptchaFlow: false,
    );
  }
}
