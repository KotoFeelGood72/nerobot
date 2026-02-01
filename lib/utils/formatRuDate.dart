import 'package:intl/intl.dart';

/// Преобразует [src] в строку "день месяц год".
/// [src] может быть:
///   • int   – миллисекунды с 1 января 1970 (как в Firestore)
///   • DateTime
String formatRuDate(dynamic src) {
  // преобразуем в DateTime
  final date = switch (src) {
    int ms => DateTime.fromMillisecondsSinceEpoch(ms).toLocal(),
    DateTime dt => dt.toLocal(),
    _ => throw ArgumentError('formatRuDate принимает int или DateTime'),
  };

  // шаблон для русской локали
  final formatter = DateFormat('d MMMM yyyy', 'ru_RU');
  return formatter.format(date);
}
