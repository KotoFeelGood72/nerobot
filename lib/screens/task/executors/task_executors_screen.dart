import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:nerobot/components/placeholder/customers_none_tasks.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';

@RoutePage()
class TaskExecutorsScreen extends StatelessWidget {
  final String taskId;

  const TaskExecutorsScreen({super.key, required this.taskId});

  /// Безопасное приведение значения к int
  int _safeIntCast(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Функция, которая получает список исполнителей для задания
  Future<List<Map<String, dynamic>>> _fetchExecutors() async {
    try {
      // Получаем документ задания
      final taskDoc =
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(taskId)
              .get();

      if (!taskDoc.exists) {
        return [];
      }

      final taskData = taskDoc.data()!;
      final List workers = (taskData['workers'] ?? []) as List;

      if (workers.isEmpty) {
        return [];
      }

      final usersRef = FirebaseFirestore.instance.collection('users');
      final chatsRef = FirebaseFirestore.instance.collection('chats');

      // Получаем данные всех исполнителей
      final executorsWithData = await Future.wait(
        workers.map((workerId) async {
          final userDoc = await usersRef.doc(workerId.toString()).get();
          final userData = userDoc.data() ?? {};

          // Запрос чата по order_id
          final chatQuerySnapshot =
              await chatsRef
                  .where('order_id', isEqualTo: taskId)
                  .limit(1)
                  .get();

          String chatId = '';
          if (chatQuerySnapshot.docs.isNotEmpty) {
            chatId = chatQuerySnapshot.docs.first.id;
          }

          return {
            'id': workerId.toString(),
            'photo': userData['image_url'] as String? ?? '',
            'firstName': userData['firstName'] as String? ?? '',
            'lastName': userData['lastName'] as String? ?? '',
            'rating': _safeIntCast(userData['rating']),
            'completedTasks': _safeIntCast(userData['completed_tasks']),
            'roomUUID': chatId,
          };
        }),
      );

      return executorsWithData;
    } catch (e) {
      print('Ошибка при получении исполнителей: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Исполнители', style: TextStyle(color: Colors.black)),
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
              // При нажатии на иконку "i" переходим к деталям задачи
              AutoRouter.of(context).replace(TaskDetailRoute(taskId: taskId));
            },
            child: Container(
              padding: const EdgeInsets.only(right: 8),
              child: const Icon(Icons.info_outline_rounded, size: 28),
            ),
          ),
          GestureDetector(
            onTap: () {
              // При нажатии на иконку откликов переходим к списку откликов
              AutoRouter.of(context).replace(TaskResponseRoute(taskId: taskId));
            },
            child: Container(
              padding: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.assignment_outlined, size: 28),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchExecutors(),
        builder: (context, snapshot) {
          // Пока идёт загрузка исполнителей
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Если нет данных или пустой список — показываем плейсхолдер
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const CustomersNoneTasks(
              title: "Нет исполнителей",
              text:
                  "К этому заданию пока не назначены исполнители. "
                  "Исполнители появятся здесь после назначения.",
              btn: false,
            );
          }

          // Если есть исполнители — строим ListView
          final executors = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: executors.length,
            itemBuilder: (context, index) {
              final executor = executors[index];

              return GestureDetector(
                onTap: () {
                  // При клике открываем чат с исполнителем
                  if (executor['roomUUID'] != null &&
                      (executor['roomUUID'] as String).isNotEmpty) {
                    AutoRouter.of(context).push(
                      ChatsRoute(
                        chatsId: executor['roomUUID'] as String,
                        taskId: taskId,
                      ),
                    );
                  }
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
                      // Аватар исполнителя
                      CircleAvatar(
                        radius: 24,
                        backgroundImage:
                            (executor['photo'] as String).isNotEmpty
                                ? NetworkImage(executor['photo'] as String)
                                : const AssetImage('assets/images/splash.png')
                                    as ImageProvider,
                      ),
                      const SizedBox(width: 16),
                      // Информация об исполнителе
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Имя исполнителя
                            Text(
                              '${executor['firstName']} ${executor['lastName']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Рейтинг и количество выполненных заданий
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  (executor['rating'] as int).toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.work,
                                  size: 16,
                                  color: AppColors.violet,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${executor['completedTasks']} заданий',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Статус (можно добавить позже)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.violet.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Назначен',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.violet,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Иконка чата
                      if (executor['roomUUID'] != null &&
                          (executor['roomUUID'] as String).isNotEmpty)
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.violet,
                          size: 20,
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
