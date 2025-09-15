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
    final snapshot =
        await FirebaseFirestore.instance
            .collection('responses')
            .where('order', isEqualTo: taskId)
            .get();

    final usersRef = FirebaseFirestore.instance.collection('users');
    final chatsRef = FirebaseFirestore.instance.collection('chats');

    final responsesWithUserData = await Future.wait(
      snapshot.docs.map((doc) async {
        final data = doc.data();
        final String userId = data['respondent'] as String? ?? '';

        final userDoc = await usersRef.doc(userId).get();
        final userData = userDoc.data() ?? {};

        // Запрос чата по order_id
        final chatQuerySnapshot =
            await chatsRef.where('order_id', isEqualTo: taskId).limit(1).get();

        String chatId = '';
        if (chatQuerySnapshot.docs.isNotEmpty) {
          chatId = chatQuerySnapshot.docs.first.id;
        }

        return {
          'photo': userData['image_url'] as String? ?? '',
          'firstName': userData['firstName'] as String? ?? '',
          'lastName': userData['lastName'] as String? ?? '',
          'created_at': _formatDate(data['created_time']),
          'rating': data['respondent_rating'] as int? ?? 0,
          'text': data['cover_letter'] as String? ?? '',
          'roomUUID': chatId, // Добавили chatId
        };
      }),
    );

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
        title: Text('Отклики', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Возвращаемся на экран заданий
            AutoRouter.of(context).replace(const TaskRoute());
          },
        ),
        actions: [
          GestureDetector(
            onTap: () {
              // При нажатии на иконку "i" переходим к деталям задачи (экран клиента)
              AutoRouter.of(
                context,
              ).replace(TaskDetailCustomerRoute(taskId: taskId));
            },
            child: Container(
              padding: const EdgeInsets.only(right: 8),
              child: const Icon(Icons.info_outline_rounded, size: 28),
            ),
          ),
          GestureDetector(
            onTap: () {
              // При нажатии на иконку исполнителей переходим к списку исполнителей
              AutoRouter.of(
                context,
              ).replace(TaskExecutorsRoute(taskId: taskId));
            },
            child: Container(
              padding: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.people_outline, size: 28),
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
