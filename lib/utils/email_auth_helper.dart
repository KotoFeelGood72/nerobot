import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailAuthHelper {
  static final _auth = FirebaseAuth.instance;
  static final _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  static bool isValidEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty || trimmed.contains(' ')) return false;
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(trimmed);
  }

  static String _messageOr(String? message, String fallback) {
    final trimmed = message?.trim();
    if (trimmed == null || trimmed.isEmpty) return fallback;
    return trimmed;
  }

  static String mapError(Object error) {
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'invalid-argument':
          return _messageOr(error.message, 'Неверные данные');
        case 'resource-exhausted':
          return _messageOr(
            error.message,
            'Слишком много попыток. Попробуйте позже',
          );
        case 'not-found':
          return _messageOr(error.message, 'Сначала запросите код');
        case 'deadline-exceeded':
          return _messageOr(error.message, 'Код истёк. Запросите новый');
        case 'permission-denied':
          return _messageOr(error.message, 'Неверный код');
        case 'unauthenticated':
          return _messageOr(error.message, 'Нужна авторизация');
        case 'unavailable':
        case 'internal':
          return _messageOr(error.message, 'Сервис временно недоступен');
        default:
          return _messageOr(error.message, 'Ошибка авторизации');
      }
    }

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Неверный формат email';
        case 'user-disabled':
          return 'Аккаунт заблокирован';
        case 'invalid-custom-token':
        case 'custom-token-mismatch':
          return 'Не удалось войти. Запросите код ещё раз';
        case 'too-many-requests':
          return 'Слишком много попыток. Попробуйте позже';
        case 'network-request-failed':
          return 'Нет связи с сервером. Проверьте интернет';
        default:
          return _messageOr(error.message, 'Ошибка авторизации');
      }
    }

    if (error is Exception) {
      final raw = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      if (raw.isNotEmpty) return raw;
    }

    return 'Ошибка авторизации';
  }

  /// Отправляет 6-значный OTP на email.
  /// В эмуляторе Functions может вернуть [debugCode].
  static Future<String?> sendOtp(String email) async {
    final result = await _functions.httpsCallable('sendEmailOtp').call({
      'email': email.trim(),
    });
    final data = result.data;
    if (data is Map && data['debugCode'] is String) {
      return data['debugCode'] as String;
    }
    return null;
  }

  /// Проверяет OTP и выполняет sign-in через custom token.
  static Future<UserCredential> verifyOtp({
    required String email,
    required String code,
  }) async {
    final result = await _functions.httpsCallable('verifyEmailOtp').call({
      'email': email.trim(),
      'code': code.trim(),
    });

    final data = result.data;
    final customToken = data is Map ? data['customToken'] as String? : null;
    if (customToken == null || customToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-custom-token',
        message: 'Сервер не вернул токен входа',
      );
    }

    return _auth.signInWithCustomToken(customToken);
  }

  /// Каскадное удаление аккаунта на сервере (Firestore + Storage + Auth).
  static Future<void> deleteAccount({String? email}) async {
    await _functions.httpsCallable('deleteAccount').call({
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
    });
  }
}
