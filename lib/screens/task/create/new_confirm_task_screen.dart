import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Divider.dart';
import 'package:nerobot/components/ui/location_picker.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/date_picker_utils.dart';
import 'package:nerobot/utils/edit_input_utils.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';

@RoutePage()
class NewConfirmTaskScreen extends StatefulWidget {
  const NewConfirmTaskScreen({super.key});

  @override
  State<NewConfirmTaskScreen> createState() => _NewConfirmTaskScreenState();
}

class _NewConfirmTaskScreenState extends State<NewConfirmTaskScreen> {
  String taskName = '';
  String taskDescription = '';
  int taskPrice = 0;
  DateTime? taskTerm;
  String taskCity = '';
  LatLng? taskLocation;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Здесь загрузи последние сохранённые данные из Firestore или передавай через Navigator (если нужно)
    // Можно также передавать taskId и получать order по нему
  }

  Future<void> _pickDate() async {
    DateTime? picked = await pickDate(context, initialDate: taskTerm);
    if (picked != null) {
      setState(() => taskTerm = picked);
    }
  }

  Future<void> _pickLocation() async {
    const LatLng defaultLocation = LatLng(55.7558, 37.6173); // Москва
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => LocationPickerMap(
              initialLocation: taskLocation ?? defaultLocation,
              onLocationSelected: (location, address) {
                setState(() {
                  taskLocation = location;
                  taskCity = address;
                });
              },
            ),
      ),
    );
  }

  Future<void> _submitTask() async {
    if (taskName.isEmpty ||
        taskPrice <= 0 ||
        taskCity.isEmpty ||
        taskTerm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пожалуйста, заполните все поля")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Не авторизован");

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await FirebaseFirestore.instance.collection('orders').add({
        'title': taskName,
        'description': taskDescription,
        'price': taskPrice,
        'payment_for': 'за смену',
        'lat': taskLocation?.latitude ?? 0,
        'lng': taskLocation?.longitude ?? 0,
        'address': taskCity,
        'begin_at': taskTerm!.millisecondsSinceEpoch,
        'created_date': timestamp,
        'creator': user.uid,
        'active': true,
      });

      if (mounted) {
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
          "Новое задание",
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
            Btn(
              text: isLoading ? 'Размещение...' : 'Разместить задание',
              onPressed: isLoading ? null : _submitTask,
              theme: 'violet',
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
          Text(
            taskName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Square(height: 8),
          Text(
            taskDescription,
            style: const TextStyle(fontSize: 14, color: AppColors.gray),
          ),
          const Square(),
          _buildEditableField("Стоимость", "$taskPrice ₽", () {
            showEditInput(
              context: context,
              initialValue: taskPrice.toString(),
              textColor: Colors.black,
              onSubmitted:
                  (val) => setState(() => taskPrice = int.tryParse(val) ?? 0),
              backgroundColor: Color.fromARGB(0, 42, 42, 153),
            );
          }, borderTop: true),
          _buildEditableField(
            "Выполнить до",
            taskTerm != null
                ? "${taskTerm!.day}.${taskTerm!.month} ${taskTerm!.hour}:${taskTerm!.minute}"
                : "Не выбрано",
            _pickDate,
          ),
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
