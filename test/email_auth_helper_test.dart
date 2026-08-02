import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nerobot/utils/email_auth_helper.dart';

void main() {
  group('EmailAuthHelper.isValidEmail', () {
    test('accepts valid emails', () {
      expect(EmailAuthHelper.isValidEmail('test@mail.ru'), isTrue);
      expect(EmailAuthHelper.isValidEmail(' user@example.com '), isTrue);
      expect(EmailAuthHelper.isValidEmail('name.surname@company.co.uk'), isTrue);
    });

    test('rejects invalid emails', () {
      expect(EmailAuthHelper.isValidEmail(''), isFalse);
      expect(EmailAuthHelper.isValidEmail('not-an-email'), isFalse);
      expect(EmailAuthHelper.isValidEmail('missing@domain'), isFalse);
      expect(EmailAuthHelper.isValidEmail('@nodomain.ru'), isFalse);
      expect(EmailAuthHelper.isValidEmail('spaces @mail.ru'), isFalse);
    });
  });

  group('EmailAuthHelper.mapError', () {
    test('maps FirebaseFunctionsException codes', () {
      expect(
        EmailAuthHelper.mapError(
          FirebaseFunctionsException(
            code: 'permission-denied',
            message: 'Неверный код',
          ),
        ),
        'Неверный код',
      );
      expect(
        EmailAuthHelper.mapError(
          FirebaseFunctionsException(
            code: 'resource-exhausted',
            message: '',
          ),
        ),
        'Слишком много попыток. Попробуйте позже',
      );
      expect(
        EmailAuthHelper.mapError(
          FirebaseFunctionsException(
            code: 'deadline-exceeded',
            message: 'Код истёк. Запросите новый',
          ),
        ),
        'Код истёк. Запросите новый',
      );
    });

    test('maps FirebaseAuthException codes', () {
      expect(
        EmailAuthHelper.mapError(
          FirebaseAuthException(code: 'invalid-email'),
        ),
        'Неверный формат email',
      );
      expect(
        EmailAuthHelper.mapError(
          FirebaseAuthException(code: 'network-request-failed'),
        ),
        'Нет связи с сервером. Проверьте интернет',
      );
    });

    test('falls back for unknown errors', () {
      expect(EmailAuthHelper.mapError(Exception('x')), 'x');
      expect(EmailAuthHelper.mapError(Object()), 'Ошибка авторизации');
    });
  });
}
