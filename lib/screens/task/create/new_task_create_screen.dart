// new_task_create_screen.dart

import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // если сохраняем сразу в Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Inputs.dart';
import 'package:nerobot/components/ui/location_picker.dart';
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
  final _descriptionController = TextEditingController();

  bool _isManualAddress = false;
  final _manualAddressController = TextEditingController();

  LatLng? _selectedLocation;
  String? _selectedAddress;

  // Срок выполнения (абсолютная дата и время)
  DateTime? _deadline;

  // Срочность
  String? _selectedUrgency;

  bool _isLoading = false;

  final List<String> _paymentOptions = [
    "За час",
    "За смену",
    "За неделю",
    "За месяц",
  ];
  String? _paymentFor = "За смену";

  @override
  void initState() {
    super.initState();
    // По умолчанию ставим дедлайн через час от момента открытия экрана
    _deadline = DateTime.now().add(const Duration(hours: 1));
    _getCurrentLocation();
  }

  /// Получаем текущие координаты и затем обратный геокодинг
  Future<void> _getCurrentLocation() async {
    // Проверяем, включён ли сервис локации
    if (!await Geolocator.isLocationServiceEnabled()) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);

      // Проверяем, что экран ещё «монтирован», прежде чем вызывать setState
      if (!mounted) return;
      setState(() => _selectedLocation = location);

      // После обновления _selectedLocation запускаем получение адреса
      _getAddressFromLatLng(location);
    } catch (e) {
      // В случае ошибки просто не обновляем локацию
      debugPrint("Ошибка при получении геопозиции: $e");
    }
  }

  void _updateAddressMode(String mode) {
    setState(() {
      _isManualAddress = mode == 'manual';
      if (!_isManualAddress) _manualAddressController.clear();
    });
  }

  Widget _addressModeChip({required bool active, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active ? AppColors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: active ? AppColors.black : AppColors.gray,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
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

        if (!mounted) return;
        setState(() => _selectedAddress = address);
        return;
      }
    } catch (e) {
      debugPrint("Ошибка при обратном геокодинге: $e");
    }

    if (!mounted) return;
    setState(() => _selectedAddress = "Ошибка определения адреса");
  }

  void _openLocationPicker() async {
    final initial = _selectedLocation ?? const LatLng(55.7558, 37.6173);
    // Здесь можно дождаться результата и обновить локацию/адрес
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => LocationPickerMap(
              initialLocation: initial,
              onLocationSelected: (location, address) {
                // Проверяем mounted в колбэке тоже:
                if (!mounted) return;
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

    if (!mounted) return;
    setState(() {
      _deadline = combined;
    });
  }

  void _onNextPressed() async {
    final name = _nameController.text.trim();
    final price = int.tryParse(_priceController.text.trim()) ?? 0;
    final deadline = _deadline;
    final location = _selectedLocation;
    final address =
        _isManualAddress
            ? _manualAddressController.text.trim()
            : _selectedAddress;

    final user = FirebaseAuth.instance.currentUser;
    final description = _descriptionController.text.trim();

    if (_paymentFor == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Выберите тип оплаты")));
      return;
    }

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Описание не может быть пустым")),
      );
      return;
    }

    if (address == null || address.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Укажите адрес задания")));
      return;
    }

    if (name.isEmpty ||
        price <= 0 ||
        deadline == null ||
        location == null ||
        address == null ||
        user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пожалуйста, заполните все поля")),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    final creationDate = DateTime.now();
    final duration = deadline.difference(creationDate);

    final draft = TaskDraft(
      title: name,
      price: price,
      date: creationDate,
      location: location,
      address: address,
      creatorUid: user.uid,
      executionTime: duration,
      deleted: false,
      description: description,
    );

    try {
      final data = draft.toFirestoreMap();
      data["deadline"] = deadline.millisecondsSinceEpoch;
      data["payment_for"] = _paymentFor;

      await FirebaseFirestore.instance.collection('orders').add(data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Задание успешно опубликовано"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      context.router.replaceAll([const TaskRoute()]);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка при размещении: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _manualAddressController.dispose();
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
            "Новое задание",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(width: 1, color: AppColors.border),
              ),
            ),
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
                const Text(
                  "Оплата",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.ulight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButton<String>(
                    value: _paymentFor,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: AppColors.gray,
                    ),
                    items:
                        _paymentOptions
                            .map(
                              (label) => DropdownMenuItem<String>(
                                value: label,
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    color: AppColors.black,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null && mounted) {
                        setState(() => _paymentFor = value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),

                //
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
                const Text(
                  "Срок выполнения",
                  style: TextStyle(
                    color: AppColors.gray,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: GestureDetector(
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
                                : "${_deadline!.day.toString().padLeft(2, '0')}."
                                    "${_deadline!.month.toString().padLeft(2, '0')}."
                                    "${_deadline!.year} "
                                    "${_deadline!.hour.toString().padLeft(2, '0')}:"
                                    "${_deadline!.minute.toString().padLeft(2, '0')}",
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
                ),

                const SizedBox(height: 16),

                const Text(
                  "Способ указания адреса",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.ulight,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(width: 1, color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _updateAddressMode('auto'),
                          child: _addressModeChip(
                            active: !_isManualAddress,
                            label: 'Автоопределение',
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _updateAddressMode('manual'),
                          child: _addressModeChip(
                            active: _isManualAddress,
                            label: 'Ввести вручную',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_isManualAddress)
                  // Ручной ввод адреса
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Inputs(
                        controller: _manualAddressController,
                        backgroundColor: AppColors.ulight,
                        textColor: AppColors.gray,
                        label: 'Адрес',
                      ),
                    ],
                  )
                else
                  // Автоопределение + карта
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Локация",
                        style: TextStyle(
                          color: AppColors.gray,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _openLocationPicker,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.ulight,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              width: 1,
                              color: AppColors.border,
                            ),
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
                              const Icon(
                                Icons.map_outlined,
                                color: AppColors.gray,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 32),

                // Описание
                const Text(
                  "Описание",
                  style: TextStyle(
                    color: AppColors.gray,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.bg,
                  ),
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: null,
                    maxLength: 300,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText:
                          "Опишите ваше задание максимально подробно и понятно...",
                      hintStyle: TextStyle(color: AppColors.gray),
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Кнопка “Далее”
                Btn(
                  text: _isLoading ? "Загрузка..." : "Создать задание",
                  onPressed: _isLoading ? null : _onNextPressed,
                  theme: 'violet',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
