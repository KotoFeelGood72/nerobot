import 'package:flutter/material.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/utils/formatRuDate.dart';

/// утилита: превращаем Duration в «2 дн 5 ч» - коротко и по-русски
String _humanizeDuration(Duration d) {
  if (d.inMinutes <= 0) return 'сейчас';
  final days = d.inDays;
  final hours = d.inHours % 24;
  final minutes = d.inMinutes % 60;

  final parts = <String>[];
  if (days > 0) parts.add('$days дн');
  if (hours > 0) parts.add('$hours ч');
  if (minutes > 0 && days == 0)
    parts.add('$minutes м'); // минуты показываем, когда <1 суток

  return parts.join(' ');
}

class CardTask extends StatelessWidget {
  final VoidCallback onTap;
  final Map<String, dynamic> task;

  const CardTask({super.key, required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // --- даты ---------------------------------------------------------------
    final createdMs = task['created_date'] as int?; // мс от Epoch
    final endMs = task['begin_at'] as int?; // мс от Epoch

    final created =
        createdMs != null
            ? DateTime.fromMillisecondsSinceEpoch(createdMs).toLocal()
            : null;
    final end =
        endMs != null
            ? DateTime.fromMillisecondsSinceEpoch(endMs).toLocal()
            : null;

    String deadlineText = 'Не указано';
    if (created != null && end != null) {
      final diff = end.difference(created);
      deadlineText = _humanizeDuration(diff);
    }

    // Флаг: считается ли эта задача «новой»
    final bool isNew = task['isNew'] == true;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Сама карточка
          Card(
            elevation: 2,
            shadowColor: AppColors.gray,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.black.withOpacity(0.08),
                //     blurRadius: 10,
                //     offset: const Offset(0, 5),
                //   ),
                // ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- заголовок + дата создания ----------------------------------
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task['title'] ?? 'Без названия',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        created != null ? formatRuDate(created) : 'Неизвестно',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // ---- цена + «через …» ------------------------------------------
                  Row(
                    children: [
                      const Icon(
                        Icons.currency_ruble,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task['price'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.access_time,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        deadlineText, // ← здесь теперь разница во времени
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // ---- описание ---------------------------------------------------
                  Text(
                    task['description'] ?? 'Описание отсутствует',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // Если задача новая – рисуем маленький красный кружок в правом углу
          if (isNew)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
