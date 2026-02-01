import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthConfig {
  /// Продакшн: реальная SMS + нативная reCAPTCHA
  static void configureForProduction() {
    FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: false,
      forceRecaptchaFlow: false,
    );
  }
}