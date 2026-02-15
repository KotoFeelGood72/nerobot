import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_auth_config_platform_io.dart' if (dart.library.html) 'firebase_auth_config_platform_stub.dart' as platform;

class FirebaseAuthConfig {
  /// Продакшн: реальная SMS. На iOS — принудительно веб reCAPTCHA (избегаем ошибки
  /// "captcha link" когда APNs недоступен, напр. в App Review).
  static void configureForProduction() {
    FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: false,
      forceRecaptchaFlow: platform.isIOSPlatform,
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