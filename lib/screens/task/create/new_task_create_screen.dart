// new_task_create_screen.dart

import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // (если сохраним сразу в Firestore)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Divider.dart';
import 'package:nerobot/components/ui/Inputs.dart';
import 'package:nerobot/components/ui/location_picker.dart';
import 'package:nerobot/components/ui/pick_date.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/models/task_draft.dart'; // <-- импорт вашей модели
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/task_confirmation.dart';

@RoutePage()
class NewTaskCreateScreen extends StatefulWidget {
  const NewTaskCreateScreen({Key? key}) : super(key: key);

  @override
  State<NewTaskCreateScreen> createState() => _NewTaskCreateScreenState();
}

class _NewTaskCreateScreenState extends State<NewTaskCreateScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  LatLng? _selectedLocation;
  String? _selectedAddress;

  // Срок выполнения (абсолютная дата и время)
  DateTime? _deadline;

  // Срочность
  String? _selectedUrgency;

  bool _isLoading = false;

  // Варианты срочности
  final List<String> _urgencyOptions = ['низкая', 'средняя', 'высокая'];

  @override
  void initState() {
    super.initState();
    // По умолчанию ставим дедлайн через час от момента открытия экрана
    _deadline = DateTime.now().add(const Duration(hours: 1));
    _selectedUrgency = _urgencyOptions[1]; // «средняя» по умолчанию
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    final location = LatLng(position.latitude, position.longitude);

    setState(() => _selectedLocation = location);
    _getAddressFromLatLng(location);
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = "${place.street}, ${place.locality}";
        setState(() => _selectedAddress = address);
      }
    } catch (_) {
      setState(() => _selectedAddress = "Ошибка определения адреса");
    }
  }

  void _openLocationPicker() async {
    final initial = _selectedLocation ?? const LatLng(55.7558, 37.6173);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => LocationPickerMap(
              initialLocation: initial,
              onLocationSelected: (location, address) {
                setState(() {
                  _selectedLocation = location;
                  _selectedAddress = address;
                });
              },
            ),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    // Сначала выбираем дату, потом время
    final DateTime now = DateTime.now();
    final DateTime initial = _deadline ?? now.add(const Duration(hours: 1));

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null) return;

    final TimeOfDay initialTime = TimeOfDay.fromDateTime(initial);
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (pickedTime == null) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _deadline = combined;
    });
  }

  void _onNextPressed() {
    final name = _nameController.text.trim();
    final price = int.tryParse(_priceController.text.trim()) ?? 0;
    final deadline = _deadline;
    final location = _selectedLocation;
    final address = _selectedAddress;
    final urgency = _selectedUrgency;
    final user = FirebaseAuth.instance.currentUser;

    // Проверка: все поля должны быть заполнены
    if (name.isEmpty ||
        price <= 0 ||
        deadline == null ||
        location == null ||
        address == null ||
        urgency == null ||
        user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пожалуйста, заполните все поля")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Дата создания — сейчас:
    final creationDate = DateTime.now();

    // Вычисляем разницу (Duration) между дедлайном и датой создания
    final duration = deadline.difference(creationDate);

    // Формируем TaskDraft:
    final draft = TaskDraft(
      title: name,
      price: price,
      date: creationDate, // сохраняем дату создания
      location: location,
      address: address,
      creatorUid: user.uid,
      executionTime: duration, // запись Duration вместо абсолютного времени
      urgency: urgency,
      deleted: false,
      // description пока не передаём — заполним на следующем экране
    );

    // Переходим на экран ввода описания, передавая draft
    context.router.push(NewDescRoute(draft: draft)).then((_) {
      // Если вернулись назад, отключаем индикатор загрузки
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => showExitConfirmation(context),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          title: const Text(
            "Новое задание (Шаг 1/3)",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // Название
              Inputs(
                controller: _nameController,
                backgroundColor: AppColors.ulight,
                textColor: AppColors.gray,
                label: 'Название',
                required: true,
              ),
              const SizedBox(height: 16),

              // Стоимость
              Inputs(
                controller: _priceController,
                backgroundColor: AppColors.ulight,
                textColor: AppColors.gray,
                label: 'Стоимость',
                fieldType: 'number',
                maxLength: 9,
                required: true,
              ),
              const SizedBox(height: 16),

              // Срок выполнения (дата + время)
              const Text("Срок выполнения", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDeadline,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.ulight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _deadline == null
                            ? "Выбрать дату и время"
                            : "${_deadline!.day.toString().padLeft(2, '0')}"
                                ".${_deadline!.month.toString().padLeft(2, '0')}"
                                ".${_deadline!.year} "
                                "${_deadline!.hour.toString().padLeft(2, '0')}"
                                ":${_deadline!.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(
                          color: AppColors.gray,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(Icons.schedule, color: AppColors.gray),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Срочность (Dropdown)
              const Text("Срочность", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.ulight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  underline: const SizedBox(),
                  value: _selectedUrgency,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.gray,
                  ),
                  items:
                      _urgencyOptions
                          .map(
                            (urg) => DropdownMenuItem(
                              value: urg,
                              child: Text(
                                urg[0].toUpperCase() + urg.substring(1),
                                style: const TextStyle(color: AppColors.black),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedUrgency = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Локация
              const Text("Локация", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _openLocationPicker,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.ulight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedAddress ?? "Определение адреса...",
                          style: const TextStyle(
                            color: AppColors.gray,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Icon(Icons.map_outlined, color: AppColors.gray),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Кнопка “Далее”
              Btn(
                text: _isLoading ? "Загрузка..." : "Далее: Описание",
                onPressed: _isLoading ? null : _onNextPressed,
                theme: 'violet',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
