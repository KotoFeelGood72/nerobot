// chats_screen.dart
import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Divider.dart';
import 'package:nerobot/components/ui/info_row.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/utils/send_repsponse.dart';

@RoutePage()
class TaskDetailExecutorScreen extends StatefulWidget {
  const TaskDetailExecutorScreen({super.key, required this.taskId});
  final String taskId;

  @override
  State<TaskDetailExecutorScreen> createState() =>
      _TaskDetailExecutorScreenState();
}

class _TaskDetailExecutorScreenState extends State<TaskDetailExecutorScreen> {
  Map<String, dynamic>? task;
  bool isLoading = true;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Проверка, является ли текущий пользователь исполнителем
  bool get _iAmWorker {
    final List workers = task?['workers'] ?? [];
    return workers.contains(_uid);
  }

  /// Локальные флаги статусов
  late String statusReadable;
  bool isSearching = false;
  bool isInWork = false;
  bool isClosed = false;

  /// Флаг: уже ли текущий пользователь оставлял отклик (есть ли он в массиве 'responses')
  bool get _hasResponded {
    final List responses = task?['responses'] ?? [];
    return responses.contains(_uid);
  }

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    final snap =
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.taskId)
            .get();

    if (!mounted) return;

    task = snap.data();
    _computeStatus();
    setState(() => isLoading = false);
  }

  /// Пересчитываем статус (по наличию исполнителей и дате закрытия)
  void _computeStatus() {
    final hasClosed = task?['closed_date'] != null;
    final hasWorkers = (task?['workers'] ?? []).isNotEmpty;

    if (hasClosed) {
      statusReadable = 'Завершено';
      isClosed = true;
    } else if (hasWorkers) {
      statusReadable = 'В работе';
      isInWork = true;
    } else {
      statusReadable = 'Поиск исполнителя';
      isSearching = true;
    }
  }

  /// Новый метод: обновляет статус документа заказа на "preview"
  Future<void> _confirmExecution() async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.taskId)
          .update({'status': 'preview'});
      // После успешного обновления можно вернуться назад
      if (mounted) {
        Navigator.of(context).pop(); // или любой другой навигационный шаг
      }
    } catch (e) {
      // Обработайте ошибку по необходимости
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось подтвердить выполнение: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (task == null) {
      return const Scaffold(body: Center(child: Text('Задание не найдено')));
    }

    // Короткие ссылки на списки внутри документа
    final List addInfo = task!['additional'] ?? [];
    final List workers = task!['workers'] ?? [];
    final List responses = task!['responses'] ?? [];
    final String currentStatus = task!['status'] as String;

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.bg,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //------------------ карточка ------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // заголовок
                  Text(
                    task!['title'] ?? 'Без названия',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Square(),
                  // описание
                  Text(
                    task!['description'] ?? '',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const Square(height: 24),
                  // основные данные
                  InfoRow(
                    label: 'Стоимость',
                    value: '${task!['price']} ₽',
                    hasTopBorder: true,
                    hasBottomBorder: true,
                  ),
                  InfoRow(
                    label: 'Дата начала',
                    value: (task!['begin_at'] ?? '').toString(),
                    hasBottomBorder: true,
                  ),
                  InfoRow(
                    label: 'Адрес',
                    value: task!['address'] ?? '',
                    hasBottomBorder: true,
                  ),
                  InfoRow(
                    label: 'Статус',
                    value: statusReadable,
                    hasBottomBorder: true,
                  ),
                  InfoRow(
                    label: 'Отклики',
                    value: '${responses.length}',
                    hasBottomBorder: true,
                  ),
                ],
              ),
            ),

            const Square(),
            const Spacer(),

            //------------------ actions -------------------

            // 1) Статус "Поиск исполнителя":
            //    показываем кнопки «Отказаться/Согласиться», но только если текущий пользователь
            //    еще не отправлял отклик (!_hasResponded) и сам не является исполнителем.
            if (isSearching && !_hasResponded && !_iAmWorker) ...[
              Row(
                children: [
                  Expanded(
                    child: Btn(
                      text: 'Отказаться',
                      theme: 'white',
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Btn(
                      text: 'Согласиться',
                      theme: 'violet',
                      onPressed:
                          () => openResponseModal(context, widget.taskId),
                    ),
                  ),
                ],
              ),
            ]
            // 2) Если статус «В работе» и текущий пользователь — назначенный исполнитель,
            //    показываем кнопку «Подтвердить выполнение»
            else if (isInWork && _iAmWorker && currentStatus != 'success') ...[
              SizedBox(
                width: double.infinity,
                child: Btn(
                  text: 'Подтвердить выполнение',
                  theme: 'violet',
                  // вместо openResponseModal вызываем обновление статуса
                  onPressed: _confirmExecution,
                ),
              ),
            ]
            // 3) Во всех остальных случаях (либо «Завершено», либо уже откликнулись) —
            //    показываем поясняющий текст
            else if (isSearching && _hasResponded) ...[
              Center(
                child: Text(
                  'Вы уже отправили отклик',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],

            const Square(height: 32),
          ],
        ),
      ),
    );
  }
}
