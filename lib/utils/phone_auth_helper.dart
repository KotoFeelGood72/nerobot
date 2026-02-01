import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PhoneAuthHelper {
  /// Старт авторизации по номеру телефона
  static Future<void> startPhoneSignIn({
    required String phoneNumber,
    required Function(PhoneAuthCredential) onVerificationCompleted,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(String, int?) onCodeSent,
    required Function(String) onCodeAutoRetrievalTimeout,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: timeout,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // ⚡️ Android: авто-подтверждение SMS. По доке один раз signIn — в колбэке экрана.
          debugPrint('✅ verificationCompleted (Android auto SMS)');
          onVerificationCompleted(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Ошибка верификации: ${e.code} — ${e.message}');
          onVerificationFailed(e);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('📩 Код отправлен на номер $phoneNumber');
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('⌛️ Истёк таймаут автоматического получения кода');
          onCodeAutoRetrievalTimeout(verificationId);
        },
      );
    } catch (e) {
      debugPrint('❌ Ошибка в startPhoneSignIn: $e');
      onVerificationFailed(FirebaseAuthException(
        code: 'unknown-error',
        message: e.toString(),
      ));
    }
  }
}