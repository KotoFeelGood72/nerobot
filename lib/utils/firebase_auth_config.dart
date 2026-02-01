import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthConfig {
  /// Продакшн: реальная SMS + нативная reCAPTCHA
  static void configureForProduction() {
    FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: false,
      forceRecaptchaFlow: false,
    );
  }

  /// Для локальной отладки: отключить реальную верификацию (НЕ для продакшна)
  static void configureForTesting() {
    FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
      forceRecaptchaFlow: false,
    );
  }
}