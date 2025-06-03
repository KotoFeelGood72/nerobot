import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/info_row.dart';

@RoutePage()
class ProfileStarsScreen extends StatelessWidget {
  const ProfileStarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> staticStarsData = {
      'rating': '4.9',
      'tasks_completed': 42,
      'total_earnings': 12650,
      'reviews': [
        {
          'username': 'Анна',
          'date': '2024-12-01',
          'comment': 'Отличная работа, всё сделано в срок!',
          'isPositive': true,
        },
        {
          'username': 'Иван',
          'date': '2025-01-12',
          'comment': 'Работа выполнена, но с небольшими задержками.',
          'isPositive': false,
        },
      ],
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Рейтинг')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InfoRow(label: 'Рейтинг', value: staticStarsData['rating']),
            InfoRow(
              label: 'Выполнено',
              value: '${staticStarsData['tasks_completed']} заданий',
              hasBottomBorder: true,
              hasTopBorder: true,
            ),
            InfoRow(
              label: 'Заработано',
              value: '${staticStarsData['total_earnings']} ₽',
              hasBottomBorder: true,
            ),
            const SizedBox(height: 24),
            const Text(
              'Отзывы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (staticStarsData['reviews'] != null &&
                staticStarsData['reviews'].isNotEmpty)
              ...staticStarsData['reviews'].map<Widget>((review) {
                return ReviewCard(
                  username: review['username'],
                  date: review['date'],
                  comment: review['comment'],
                  isPositive: review['isPositive'],
                );
              }).toList()
            else
              const Text('Нет отзывов'),
          ],
        ),
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final String username;
  final String date;
  final String comment;
  final bool isPositive;

  const ReviewCard({
    super.key,
    required this.username,
    required this.date,
    required this.comment,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.yellow,
                  radius: 20,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 8),
                Text(
                  username,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(date, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.add : Icons.remove,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(comment, style: const TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
