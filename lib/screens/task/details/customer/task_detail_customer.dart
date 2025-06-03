import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Divider.dart';
import 'package:nerobot/components/ui/Inputs.dart';
import 'package:nerobot/components/ui/info_row.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/utils/modal_utils.dart';

@RoutePage()
class TaskDetailCustomerScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailCustomerScreen({super.key, required this.taskId});

  @override
  State<TaskDetailCustomerScreen> createState() =>
      _TaskDetailCustomerScreenState();
}

class _TaskDetailCustomerScreenState extends State<TaskDetailCustomerScreen> {
  final TextEditingController responseController = TextEditingController();

  Future<Map<String, dynamic>?> _fetchTask(String id) async {
    final doc =
        await FirebaseFirestore.instance.collection('tasks').doc(id).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> _sendTaskResponse(String text) async {
    await FirebaseFirestore.instance.collection('responses').add({
      'taskId': widget.taskId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Детали задачи')),
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
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                      Text(
                        task['taskName'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Square(),
                      Text(
                        task['taskDescription'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const Square(height: 32),
                      InfoRow(
                        label: 'Стоимость',
                        value: '${task['taskPrice']} ₽',
                        hasTopBorder: true,
                        hasBottomBorder: true,
                      ),
                      InfoRow(
                        label: 'Срок выполнения',
                        value: task['taskTerm'] ?? '',
                        hasBottomBorder: true,
                      ),
                      InfoRow(
                        label: 'Размещено',
                        value: task['taskCreated'] ?? '',
                        hasBottomBorder: true,
                      ),
                      InfoRow(
                        label: 'Статус',
                        value: task['taskStatus'] ?? 'Поиск исполнителя',
                        hasBottomBorder: true,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: Btn(
                    text: 'Подтвердить выполнение',
                    theme: 'violet',
                    onPressed: () => _openResponseModal(context),
                  ),
                ),
                const Square(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
