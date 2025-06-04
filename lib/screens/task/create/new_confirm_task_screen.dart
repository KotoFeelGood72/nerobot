// new_confirm_task_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Divider.dart';
import 'package:nerobot/components/ui/location_picker.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/models/task_draft.dart'; // <-- импорт модели TaskDraft
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/date_picker_utils.dart';
import 'package:nerobot/utils/edit_input_utils.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';

@RoutePage()
class NewConfirmTaskScreen extends StatefulWidget {
  final TaskDraft draft;

  const NewConfirmTaskScreen({Key? key, required this.draft}) : super(key: key);

  @override
  State<NewConfirmTaskScreen> createState() => _NewConfirmTaskScreenState();
}

class _NewConfirmTaskScreenState extends State<NewConfirmTaskScreen> {
  late String taskName;
  late String taskDescription;
  late int taskPrice;

  /// В модели executionTime хранится Duration от момента создания до дедлайна.
  /// Здесь будем хранить локально абсолютный дедлайн:
  DateTime? taskDeadline;

  late String taskCity;
  LatLng? taskLocation;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    // Из черновика берем:
    taskName = widget.draft.title;
    taskDescription = widget.draft.description ?? '';
    taskPrice = widget.draft.price;
    taskLocation = widget.draft.location;
    taskCity = widget.draft.address ?? '';

    // Вычисляем абсолютный дедлайн:
    // дедлайн = дата создания (draft.date) + duration (draft.executionTime)
    taskDeadline = widget.draft.date.add(widget.draft.executionTime);

    // Если локация/адрес отсутствуют, подставляем дефолт:
    if (taskLocation == null) {
      taskLocation = const LatLng(55.7558, 37.6173); // Москва
    }
    if (taskCity.isEmpty) {
      taskCity = 'Не указано';
    }
  }

  Future<void> _pickDate() async {
    // При выборе даты/времени мы обновляем taskDeadline,
    // а затем пересчитываем draft.executionTime = taskDeadline - draft.date
    DateTime? picked = await pickDate(context, initialDate: taskDeadline);
    if (picked != null) {
      setState(() {
        taskDeadline = picked;
        final newDuration = picked.difference(widget.draft.date);
        // Обязательно не давать отрицательную длительность:
        widget.draft.executionTime =
            newDuration.isNegative ? Duration.zero : newDuration;
      });
    }
  }

  Future<void> _pickLocation() async {
    final LatLng defaultLoc = taskLocation ?? const LatLng(55.7558, 37.6173);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => LocationPickerMap(
              initialLocation: defaultLoc,
              onLocationSelected: (location, address) {
                setState(() {
                  taskLocation = location;
                  taskCity = address;
                });
                widget.draft.location = location;
                widget.draft.address = address;
              },
            ),
      ),
    );
  }

  Future<void> _submitTask() async {
    // Проверяем, что все ключевые поля заданы:
    if (taskName.isEmpty ||
        taskPrice <= 0 ||
        taskCity.isEmpty ||
        taskDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пожалуйста, заполните все поля")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Не авторизован");

      // Подготовим данные для записи:
      final data = widget.draft.toFirestoreMap();

      // Если в модели .toFirestoreMap() используется:
      //   "begin_at": date.millisecondsSinceEpoch,
      //   "execution_time": executionTime.inMilliseconds,
      // то draft.date уже указывает на момент создания,
      // draft.executionTime — Duration до дедлайна.

      // Если вы хотите в коллекции ‘orders’ хранить еще абсолютный дедлайн,
      // можно добавить поле "deadline": taskDeadline.millisecondsSinceEpoch.
      data["deadline"] = taskDeadline!.millisecondsSinceEpoch;

      await FirebaseFirestore.instance.collection('orders').add(data);

      if (mounted) {
        // После успешной записи — уходим к списку задач:
        AutoRouter.of(context).replaceAll([const TaskRoute()]);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка при размещении: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Подтвердите задание",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTaskPreviewCard(),
            const Spacer(),
            Container(
              width: double.infinity,
              child: Btn(
                text: isLoading ? 'Размещение...' : 'Разместить задание',
                onPressed: isLoading ? null : _submitTask,
                theme: 'violet',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // — Название (не редактируется)
          Text(
            taskName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Square(height: 8),

          // — Описание (не редактируется)
          Text(
            taskDescription,
            style: const TextStyle(fontSize: 14, color: AppColors.gray),
          ),
          const Square(),

          // — Редактируемая стоимость
          _buildEditableField("Стоимость", "$taskPrice ₽", () {
            showEditInput(
              context: context,
              initialValue: taskPrice.toString(),
              textColor: Colors.black,
              onSubmitted: (val) {
                final parsed = int.tryParse(val) ?? 0;
                setState(() => taskPrice = parsed);
                widget.draft.price = parsed;
              },
              backgroundColor: const Color.fromARGB(0, 42, 42, 153),
            );
          }, borderTop: true),

          // — Редактируемый дедлайн (абсолютный)
          _buildEditableField(
            "Выполнить до",
            taskDeadline != null
                ? "${taskDeadline!.day.toString().padLeft(2, '0')}."
                    "${taskDeadline!.month.toString().padLeft(2, '0')} "
                    "${taskDeadline!.hour.toString().padLeft(2, '0')}:"
                    "${taskDeadline!.minute.toString().padLeft(2, '0')}"
                : "Не выбрано",
            _pickDate,
          ),

          // — Редактируемая локация
          _buildEditableField(
            "Локация",
            taskCity.isNotEmpty ? taskCity : "Укажите",
            _pickLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(
    String title,
    String value,
    VoidCallback onEdit, {
    bool borderTop = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: const BorderSide(color: AppColors.border),
          top:
              borderTop
                  ? const BorderSide(color: AppColors.border)
                  : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          Text("$title: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: AppColors.gray),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onEdit,
            child: const Icon(
              Icons.edit_outlined,
              color: AppColors.violet,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
