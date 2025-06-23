import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/constants/app_colors.dart';

class TaskFilters extends StatefulWidget {
  final Function(Map<String, dynamic>) onApply;

  const TaskFilters({super.key, required this.onApply});

  @override
  State<TaskFilters> createState() => _TaskFiltersState();
}

class _TaskFiltersState extends State<TaskFilters> {
  double? _minPrice;
  double? _maxPrice;
  String? _shiftType;
  double _radiusKm = 5;
  LatLng? _userLocation;

  final List<String> _shiftOptions = [
    'За смену',
    'За час',
    'За неделю',
    'За месяц',
  ];

  final List<String> _sortOptions = ['По дате', 'По стоимости'];

  String? _sortBy;

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
    });
  }

  void _applyFilters() {
    final filters = <String, dynamic>{
      'minPrice': _minPrice,
      'maxPrice': _maxPrice,
      'shiftType': _shiftType,
      'userLocation': _userLocation,
      'radiusKm': _radiusKm,
      'sortBy': _sortBy,
    };

    widget.onApply(filters);
    Navigator.pop(context); // Закрыть BottomSheet после применения
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => Padding(
            padding: MediaQuery.of(
              context,
            ).viewInsets.add(const EdgeInsets.all(16)),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Фильтры",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  // 💰 Цена
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Мин. цена",
                          ),
                          onChanged: (v) => _minPrice = double.tryParse(v),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Макс. цена",
                          ),
                          onChanged: (v) => _maxPrice = double.tryParse(v),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ⏱️ Период оплаты
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Оплата за"),
                    items:
                        _shiftOptions
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (value) => setState(() => _shiftType = value),
                  ),

                  const SizedBox(height: 12),

                  // 🧭 Сортировка
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Сортировка"),
                    items:
                        _sortOptions
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (value) => setState(() => _sortBy = value),
                  ),

                  const SizedBox(height: 12),

                  // 📍 Радиус
                  if (_userLocation != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Радиус поиска (км)"),
                        Slider(
                          value: _radiusKm,
                          min: 1,
                          max: 50,
                          divisions: 49,
                          label: "${_radiusKm.round()} км",
                          onChanged: (value) {
                            setState(() {
                              _radiusKm = value;
                            });
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  Btn(
                    text: 'Применить фильтры',
                    theme: 'violet',
                    onPressed: _applyFilters,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _openFilterSheet,
        icon: const Icon(Icons.filter_list),
        label: const Text("Фильтры"),
        style: TextButton.styleFrom(foregroundColor: AppColors.violet),
      ),
    );
  }
}
