import 'dart:convert';

/// Ключи настроек push-уведомлений в Firestore.
class NotificationPrefs {
  static const cityTask = 'cityTask';
  static const newTasks = 'newTasks';
  static const messages = 'messages';
  static const orderResponse = 'orderResponse';
  static const inactiveReminder = 'inactiveReminder';

  static const defaults = <String, bool>{
    cityTask: true,
    newTasks: true,
    messages: true,
    orderResponse: true,
    inactiveReminder: true,
  };
}

/// FCM-топики для массовых уведомлений.
class NotificationTopics {
  static const newTasks = 'new_tasks';

  static String cityTopicId(String city) {
    final normalized = city.trim().toLowerCase();
    if (normalized.isEmpty) return '';
    final encoded = base64Url
        .encode(utf8.encode(normalized))
        .replaceAll('=', '')
        .substring(0, 16);
    return 'city_$encoded';
  }
}

/// Android notification channel (должен совпадать с AndroidManifest и Cloud Functions).
/// v2: старый канал мог остаться с низкой importance — Android не обновляет его.
class NotificationChannels {
  static const highImportanceId = 'nerobot_alerts_v2';
  static const highImportanceName = 'Важные уведомления';
  static const highImportanceDescription =
      'Задания, сообщения, отклики и напоминания';
}
