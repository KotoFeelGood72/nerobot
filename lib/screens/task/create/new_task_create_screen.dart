import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auto_route/auto_route.dart';
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
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/task_confirmation.dart';

@RoutePage()
class NewTaskCreateScreen extends StatefulWidget {
  const NewTaskCreateScreen({super.key});

  @override
  State<NewTaskCreateScreen> createState() => _NewTaskCreateScreenState();
}

class _NewTaskCreateScreenState extends State<NewTaskCreateScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  LatLng? _selectedLocation;
  String? _selectedAddress;
  DateTime? _selectedDate;
  bool _isLoading = false;

  // 🔹 Локальный стейт задачи
  Map<String, dynamic> _localTaskData = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
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

  Future<void> _createTask() async {
    final name = _nameController.text.trim();
    final price = int.tryParse(_priceController.text.trim()) ?? 0;
    final location = _selectedLocation;
    final address = _selectedAddress ?? '';
    final createdAt = DateTime.now().millisecondsSinceEpoch;
    final user = FirebaseAuth.instance.currentUser;

    if (name.isEmpty || price <= 0 || location == null || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Пожалуйста, заполните все поля")),
      );
      return;
    }

    final taskData = {
      "title": name,
      "description": name,
      "price": price,
      "payment_for": "за смену",
      "lat": location.latitude,
      "lng": location.longitude,
      "address": address,
      "begin_at": createdAt,
      "created_date": createdAt,
      "creator": user.uid,
      "active": true,
    };

    // 🔹 Сохраняем в локальный стейт
    setState(() {
      _isLoading = true;
      _localTaskData = taskData;
    });

    try {
      await FirebaseFirestore.instance.collection('orders').add(taskData);

      if (mounted) {
        AutoRouter.of(context).replace(NewDescRoute());
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            "Новое задание",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Inputs(
                controller: _nameController,
                backgroundColor: AppColors.ulight,
                textColor: AppColors.gray,
                label: 'Название',
                required: true,
              ),
              const Square(),

              Inputs(
                controller: _priceController,
                backgroundColor: AppColors.ulight,
                textColor: AppColors.gray,
                label: 'Стоимость',
                fieldType: 'number',
                maxLength: 9,
                required: true,
              ),
              const Square(),

              PickDate(
                initialDate: _selectedDate!,
                onDatePicked: (date) => setState(() => _selectedDate = date),
              ),
              const Square(),

              const Text("Локация", style: TextStyle(fontSize: 16)),
              const Square(height: 8),
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
                      Text(
                        _selectedAddress ?? "Определение адреса...",
                        style: const TextStyle(
                          color: AppColors.gray,
                          fontSize: 16,
                        ),
                      ),
                      const Icon(Icons.map_outlined, color: AppColors.gray),
                    ],
                  ),
                ),
              ),
              const Square(),

              Btn(
                text: _isLoading ? "Создание..." : "Продолжить",
                onPressed: _isLoading ? null : _createTask,
                theme: 'violet',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
