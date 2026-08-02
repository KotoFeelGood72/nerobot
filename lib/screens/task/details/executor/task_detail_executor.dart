import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Divider.dart';
import 'package:nerobot/components/ui/info_row.dart';
import 'package:nerobot/components/ui/linkable_selectable_text.dart';
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
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _uidInList(dynamic list) {
    if (_uid.isEmpty || list is! List) return false;
    return list.any((e) => e?.toString() == _uid);
  }

  bool _iAmWorker(Map<String, dynamic> task) =>
      _uidInList(task['workers']);

  bool _hasResponded(Map<String, dynamic> task) =>
      _uidInList(task['responses']);

  ({String label, bool searching, bool inWork, bool closed}) _statusOf(
    Map<String, dynamic> task,
  ) {
    final status = task['status']?.toString();
    final hasClosed =
        task['closed_date'] != null ||
        status == 'success' ||
        status == 'done' ||
        status == 'cancelled';
    final hasWorkers = (task['workers'] is List) &&
        (task['workers'] as List).isNotEmpty;

    if (hasClosed) {
      return (label: 'Завершено', searching: false, inWork: false, closed: true);
    }
    if (status == 'preview') {
      return (label: 'На проверке', searching: false, inWork: true, closed: false);
    }
    if (hasWorkers || status == 'working') {
      return (label: 'В работе', searching: false, inWork: true, closed: false);
    }
    return (
      label: 'Поиск исполнителя',
      searching: true,
      inWork: false,
      closed: false,
    );
  }

  String _formatTimestamp(dynamic raw) {
    final millis = raw is num
        ? raw.toInt()
        : int.tryParse(raw?.toString() ?? '');
    if (millis == null || millis <= 0) return '—';
    final dt = DateTime.fromMillisecondsSinceEpoch(millis).toLocal();
    return DateFormat('dd.MM.yyyy HH:mm').format(dt);
  }

  Future<void> _confirmExecution() async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.taskId)
          .update({'status': 'preview'});
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось подтвердить выполнение: $e')),
      );
    }
  }

  Future<void> _openResponse() async {
    await openResponseModal(context, widget.taskId);
    // Stream обновит UI; setState на случай если модалку закрыли без отклика
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.taskId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('Задание не найдено'));
          }

          final task = snap.data!.data()!;
          final responses = task['responses'] is List
              ? task['responses'] as List
              : const [];
          final currentStatus = task['status']?.toString() ?? 'open';
          final status = _statusOf(task);
          final hasResponded = _hasResponded(task);
          final iAmWorker = _iAmWorker(task);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.bg,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['title'] ?? 'Без названия',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Square(),
                      LinkableSelectableText(
                        task['description']?.toString() ?? '',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const Square(height: 24),
                      InfoRow(
                        label: 'Стоимость',
                        value: '${task['price']} ₽',
                        hasTopBorder: true,
                        hasBottomBorder: true,
                      ),
                      InfoRow(
                        label: 'Дата начала',
                        value: _formatTimestamp(
                          task['deadline'] ?? task['begin_at'],
                        ),
                        hasBottomBorder: true,
                      ),
                      InfoRow(
                        label: 'Адрес',
                        value: task['address'] ?? '',
                        hasBottomBorder: true,
                      ),
                      InfoRow(
                        label: 'Статус',
                        value: status.label,
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
                if (status.searching && !hasResponded && !iAmWorker)
                  Row(
                    children: [
                      Expanded(
                        child: Btn(
                          text: 'Отказаться',
                          theme: 'secondary',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Btn(
                          text: 'Согласиться',
                          theme: 'primary',
                          onPressed: _openResponse,
                        ),
                      ),
                    ],
                  )
                else if (status.inWork &&
                    iAmWorker &&
                    currentStatus != 'success')
                  SizedBox(
                    width: double.infinity,
                    child: Btn(
                      text: 'Подтвердить выполнение',
                      theme: 'primary',
                      onPressed: _confirmExecution,
                    ),
                  )
                else if (status.searching && hasResponded)
                  Center(
                    child: Text(
                      'Вы уже отправили отклик',
                      style: TextStyle(color: Colors.grey[600]),
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
