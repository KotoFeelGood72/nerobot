import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Divider.dart';
import 'package:nerobot/components/ui/Inputs.dart';
import 'package:nerobot/components/ui/info_row.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/modal_utils.dart';
import 'package:intl/intl.dart'; // для форматирования даты

@RoutePage()
class TaskDetailCustomerScreen extends StatefulWidget {
  final String taskId;
  final String? respondent;

  const TaskDetailCustomerScreen({
    super.key,
    required this.taskId,
    this.respondent,
  });

  @override
  State<TaskDetailCustomerScreen> createState() =>
      _TaskDetailCustomerScreenState();
}

class _TaskDetailCustomerScreenState extends State<TaskDetailCustomerScreen> {
  final TextEditingController responseController = TextEditingController();

  /// Читаем один документ из коллекции "orders"
  Future<Map<String, dynamic>?> _fetchTask(String id) async {
    final doc =
        await FirebaseFirestore.instance.collection('orders').doc(id).get();
    return doc.exists ? doc.data() : null;
  }

  /// Отправляем отклик (комментарий) по задаче в отдельную коллекцию "responses"
  Future<void> _sendTaskResponse(String text) async {
    await FirebaseFirestore.instance.collection('responses').add({
      'taskId': widget.taskId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _confirmSuccess() async {
    final docRef = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.taskId);
    try {
      await docRef.update({'status': 'success'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Статус изменён на Success')),
        );
        // Переходим на TaskRoute
        context.router.replace(const TaskRoute());
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при обновлении статуса: $e')),
      );
    }
  }

  Future<void> _confirmWorker() async {
    if (widget.respondent == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.taskId);

    await docRef.update({
      'workers': [widget.respondent],
      'responses': [],
      'status': 'working',
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Исполнитель утверждён')));
      setState(() {});
    }
  }

  /// Открываем модальное с вводом комментария
  void _openResponseModal(BuildContext context) {
    showCustomModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: AppColors.bg,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Комментарий к задаче',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Inputs(
                backgroundColor: Colors.white,
                textColor: Colors.black,
                controller: responseController,
                label: 'Комментарий',
                fieldType: 'text',
                isMultiline: true,
                required: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Btn(
                      text: 'Отмена',
                      theme: 'white',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Btn(
                      text: 'Подтвердить',
                      theme: 'violet',
                      onPressed: () async {
                        try {
                          await _sendTaskResponse(responseController.text);
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Комментарий отправлен'),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                        }
                      },
                    ),
                  ),
                ],
              ),
              const Square(height: 32),
            ],
          ),
        );
      },
    );
  }

  /// Форматируем unix-timestamp (ms) в «дд.MM.yyyy HH:mm»
  String _formatTimestamp(int? millis) {
    if (millis == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
    return DateFormat('dd.MM.yyyy HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Детали заказа')),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchTask(widget.taskId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Задача не найдена'));
          }

          final task = snapshot.data!;
          // Достаём нужные поля
          final String title = task['title'] ?? '';
          final String description = task['description'] ?? '';
          final int price = (task['price'] is int) ? task['price'] as int : 0;
          final int? beginAt = task['begin_at'] as int?;
          final String address = task['address'] ?? '';
          final bool isActive = task['active'] as bool? ?? false;

          // Список исполнителей и статус
          final List<dynamic>? workersList = task['workers'] as List<dynamic>?;
          final bool hasExecutor =
              workersList != null && workersList.isNotEmpty;
          final String? status = task['status'] as String?;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Карточка с данными заказа ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название задачи
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Описание задачи
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Стоимость
                      InfoRow(
                        label: 'Стоимость',
                        value: '$price ₽',
                        hasTopBorder: true,
                        hasBottomBorder: true,
                      ),

                      // Дата/время начала
                      InfoRow(
                        label: 'Дата начала',
                        value: _formatTimestamp(beginAt),
                        hasBottomBorder: true,
                      ),

                      // Адрес
                      InfoRow(
                        label: 'Адрес',
                        value: address,
                        hasBottomBorder: true,
                      ),

                      // Статус (active)
                      InfoRow(
                        label: 'Статус',
                        value: isActive ? 'Активен' : 'Не активен',
                        hasBottomBorder: true,
                      ),

                      // Если есть исполнитель — выводим его UID
                      if (hasExecutor) ...[
                        InfoRow(
                          label: 'Исполнитель',
                          value: workersList!.join(', '),
                          hasBottomBorder: true,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- Блок с кнопками, но только если статус != "success" ---
                if (status != 'success') ...[
                  if (widget.respondent != null && !hasExecutor) ...[
                    Btn(
                      text: 'Утвердить исполнителя',
                      theme: 'violet',
                      onPressed: _confirmWorker,
                    ),
                  ] else if (hasExecutor) ...[
                    Btn(
                      text: 'Подтвердить выполнение',
                      theme: 'violet',
                      onPressed: _confirmSuccess,
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
