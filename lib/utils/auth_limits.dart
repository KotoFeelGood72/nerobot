class AuthLimits {
  // Лимиты для запроса кода
  static const int maxCodeRequests = 5;
  static const int codeRequestCooldownSeconds = 30;

  // Лимиты для повторной отправки кода
  static const int maxResendAttempts = 3;
  static const int resendCooldownSeconds = 60;

  // Лимиты для ввода кода
  static const int maxCodeAttempts = 5;
  static const int codeAttemptCooldownSeconds = 60;

  // Время блокировки после превышения лимитов
  static const int lockoutDurationMinutes = 15;

  /// Проверяет, можно ли сделать запрос кода
  static bool canRequestCode(int attempts, DateTime? lastAttempt) {
    if (attempts >= maxCodeRequests) return false;

    if (lastAttempt != null) {
      final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);
      return timeSinceLastAttempt.inSeconds >= codeRequestCooldownSeconds;
    }

    return true;
  }

  /// Возвращает оставшееся время до следующей попытки
  static int getRemainingCooldownSeconds(DateTime? lastAttempt) {
    if (lastAttempt == null) return 0;

    final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);
    final remaining =
        codeRequestCooldownSeconds - timeSinceLastAttempt.inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Проверяет, можно ли повторно отправить код
  static bool canResendCode(int attempts, DateTime? lastAttempt) {
    if (attempts >= maxResendAttempts) return false;

    if (lastAttempt != null) {
      final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);
      return timeSinceLastAttempt.inSeconds >= resendCooldownSeconds;
    }

    return true;
  }

  /// Проверяет, можно ли ввести код
  static bool canEnterCode(int attempts, DateTime? lastAttempt) {
    if (attempts >= maxCodeAttempts) return false;

    if (lastAttempt != null) {
      final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);
      return timeSinceLastAttempt.inSeconds >= codeAttemptCooldownSeconds;
    }

    return true;
  }

  /// Проверяет, заблокирован ли пользователь
  static bool isUserLocked(DateTime? lockoutTime) {
    if (lockoutTime == null) return false;

    final timeSinceLockout = DateTime.now().difference(lockoutTime);
    return timeSinceLockout.inMinutes < lockoutDurationMinutes;
  }

  /// Возвращает время до разблокировки
  static int getLockoutRemainingMinutes(DateTime? lockoutTime) {
    if (lockoutTime == null) return 0;

    final timeSinceLockout = DateTime.now().difference(lockoutTime);
    final remaining = lockoutDurationMinutes - timeSinceLockout.inMinutes;
    return remaining > 0 ? remaining : 0;
  }
}
