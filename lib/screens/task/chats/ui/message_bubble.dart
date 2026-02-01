import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nerobot/constants/app_colors.dart';

class MessageBubble extends StatelessWidget {
  /// данные одного сообщения из Firestore
  final Map<String, dynamic> message;

  /// принадлежит ли сообщение текущему пользователю
  final bool isMine;

  const MessageBubble({super.key, required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final String text = message['text'] ?? '';

    // ─── форматируем «HH:mm» ────────────────────────────────────────────────
    final int? tsMillis = message['date_time'];
    final String time =
        tsMillis != null
            ? DateFormat(
              'HH:mm',
            ).format(DateTime.fromMillisecondsSinceEpoch(tsMillis).toLocal())
            : '';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isMine ? AppColors.violet : AppColors.border,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMine ? Colors.white : Colors.black,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: (isMine ? Colors.white70 : Colors.black54),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
