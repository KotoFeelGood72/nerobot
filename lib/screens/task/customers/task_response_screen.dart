// task_response_screen.dart

import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:nerobot/components/placeholder/customers_none_tasks.dart';
import 'package:nerobot/router/app_router.gr.dart';

@RoutePage()
class TaskResponseScreen extends StatelessWidget {
  final String taskId;

  const TaskResponseScreen({super.key, required this.taskId});

  /// Функция, которая вытягивает из Firestore все документы "responses",
  /// где поле "order" совпадает с переданным taskId, и сразу же для каждого
  /// отклика дополняет его данными пользователя из коллекции "users".
  Future<List<Map<String, dynamic>>> _fetchResponses() async {
    // 1. Получаем все документы откликов, привязанных к этой задаче
    final snapshot =
        await FirebaseFirestore.instance
            .collection('responses')
            .where('order', isEqualTo: taskId)
            .get();

    final usersRef = FirebaseFirestore.instance.collection('users');

    // 2. Параллельно для каждого документа "response" получаем информацию о юзере
    final responsesWithUserData = await Future.wait(
      snapshot.docs.map((doc) async {
        final data = doc.data();

        // Предположим, что в документе есть поле "respondent" (UID пользователя)
        final String userId = data['respondent'] as String? ?? '';

        // 2.1. Загружаем документ пользователя
        final DocumentSnapshot userDoc = await usersRef.doc(userId).get();
        final userData =
            userDoc.data() as Map<String, dynamic>? ?? <String, dynamic>{};

        // Составляем итоговую карту для отображения
        return <String, dynamic>{
          // Аватар пользователя (если пусто, можно будет показать дефолт)
          'photo': userData['image_url'] as String? ?? '',
          // Берём firstName/lastName из профиля юзера (если их нет, ставим "Без имени")
          'firstName': userData['firstName'] as String? ?? '',
          'lastName': userData['lastName'] as String? ?? '',
          // Дата отклика: используем поле "created_time" (ms unix), форматируем ниже
          'created_at': _formatDate(data['created_time']),
          // Рейтинг (откликнувшегося) из поля "respondent_rating"
          'rating': data['respondent_rating'] as int? ?? 0,
          // Текст сопроводительного письма (cover_letter)
          'text': data['cover_letter'] as String? ?? '',

          // ID документа отклика (нужно, чтобы потом открыть чат по roomUUID)
        };
      }),
    );
    print(taskId);

    return responsesWithUserData;
  }

  /// Преобразуем unix-таймстамп (ms) в строку вида "dd.MM.yyyy"
  String _formatDate(dynamic timestamp) {
    try {
      final int? millis =
          (timestamp is int) ? timestamp : int.tryParse(timestamp.toString());
      if (millis == null) return '';
      final DateTime date = DateTime.fromMillisecondsSinceEpoch(millis);
      return '${date.day.toString().padLeft(2, '0')}.'
          '${date.month.toString().padLeft(2, '0')}.'
          '${date.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Отклики $taskId', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          GestureDetector(
            onTap: () {
              // При нажатии на иконку "i" переходим к деталям задачи (экран клиента)
              AutoRouter.of(
                context,
              ).push(TaskDetailCustomerRoute(taskId: taskId));
            },
            child: Container(
              padding: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.info_outline_rounded, size: 28),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchResponses(),
        builder: (context, snapshot) {
          // Пока идёт загрузка откликов
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Если нет данных или пустой список — показываем плейсхолдер
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const CustomersNoneTasks(
              title: "Еще никто не откликнулся",
              text:
                  "Как только кто-то проявит интерес к вашему заданию, "
                  "они появятся здесь. Следите за уведомлениями!",
              btn: false,
            );
          }

          // Если есть хотя бы один отклик — строим ListView
          final responses = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: responses.length,
            itemBuilder: (context, index) {
              final response = responses[index];

              return GestureDetector(
                onTap: () {
                  // При клике открываем чат по соответствующему roomUUID
                  AutoRouter.of(context).push(
                    ChatsRoute(
                      chatsId: response['roomUUID'] as String,
                      taskId: taskId,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Аватар пользователя
                      CircleAvatar(
                        radius: 24,
                        backgroundImage:
                            (response['photo'] as String).isNotEmpty
                                ? NetworkImage(response['photo'] as String)
                                : const AssetImage('assets/images/splash.png')
                                    as ImageProvider,
                      ),
                      const SizedBox(width: 16),
                      // Имя, дата, рейтинг и текст сопроводительного письма
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Первая строка: ФИО и дата
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${response['firstName']} ${response['lastName']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  response['created_at'] as String,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Вторая строка: значок рейтинга и цифра
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (response['rating'] as int).toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Текст сопроводительного письма (максимум 2 строки)
                            Text(
                              response['text'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
