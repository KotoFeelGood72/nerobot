import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Inputs.dart';
import 'package:nerobot/constants/app_colors.dart';

class TaskFilters extends StatefulWidget {
  final Function(Map<String, dynamic>) onApply;

  const TaskFilters({super.key, required this.onApply});

  @override
  State<TaskFilters> createState() => _TaskFiltersState();
}

class _TaskFiltersState extends State<TaskFilters> {
  final _minPriceController = TextEditingController();
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

  @override
  void dispose() {
    _minPriceController.dispose();
    super.dispose();
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
      'minPrice': double.tryParse(_minPriceController.text),
      'shiftType': _shiftType,
      'userLocation': _userLocation,
      'radiusKm': _radiusKm,
      'sortBy': _sortBy,
    };

    // Отладочная информация
    print('Применяем фильтры:');
    print('minPrice: ${filters['minPrice']}');
    print('shiftType: ${filters['shiftType']}');
    print('radiusKm: ${filters['radiusKm']}');
    print('sortBy: ${filters['sortBy']}');

    widget.onApply(filters);
    Navigator.pop(context); // Закрыть BottomSheet после применения
  }

  void _resetFilters() {
    setState(() {
      _minPriceController.clear();
      _shiftType = null;
      _radiusKm = 5;
      _sortBy = null;
    });
  }

  void _resetFiltersInModal(StateSetter setModalState) {
    setModalState(() {
      _minPriceController.clear();
      _shiftType = null;
      _radiusKm = 5;
      _sortBy = null;
    });
  }

  void _openFilterSheet() {
    print('Открываем фильтры, текущий радиус: $_radiusKm');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        print('Builder вызван, радиус: $_radiusKm');
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: MediaQuery.of(
                context,
              ).viewInsets.add(const EdgeInsets.all(16)),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Фильтры",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 💰 Минимальная цена
                    Inputs(
                      controller: _minPriceController,
                      backgroundColor: AppColors.ulight,
                      textColor: AppColors.gray,
                      label: 'Мин. цена',
                      fieldType: 'number',
                      maxLength: 9,
                    ),

                    const SizedBox(height: 16),

                    // ⏱️ Период оплаты и Сортировка в одной строке
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Оплата за",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.ulight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: DropdownButton<String>(
                                  value: _shiftType,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: AppColors.gray,
                                  ),
                                  hint: const Text(
                                    "Выберите тип оплаты",
                                    style: TextStyle(color: AppColors.gray),
                                  ),
                                  items:
                                      _shiftOptions
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
                                    print('Выбрана оплата: $value');
                                    setModalState(() {
                                      _shiftType = value;
                                      print(
                                        'Обновлено _shiftType: $_shiftType',
                                      );
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Сортировка",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.ulight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: DropdownButton<String>(
                                  value: _sortBy,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: AppColors.gray,
                                  ),
                                  hint: const Text(
                                    "Выберите сортировку",
                                    style: TextStyle(color: AppColors.gray),
                                  ),
                                  items:
                                      _sortOptions
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
                                    print('Выбрана сортировка: $value');
                                    setModalState(() {
                                      _sortBy = value;
                                      print('Обновлено _sortBy: $_sortBy');
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 📍 Радиус
                    if (_userLocation != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Радиус поиска (км)",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.gray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Slider(
                            value: _radiusKm,
                            min: 1,
                            max: 50,
                            divisions: 49,
                            label: "${_radiusKm.round()} км",
                            onChanged: (value) {
                              print('Изменен радиус: $value км');
                              print('До setModalState _radiusKm: $_radiusKm');
                              setModalState(() {
                                _radiusKm = value;
                                print(
                                  'Внутри setModalState _radiusKm: $_radiusKm',
                                );
                              });
                              print(
                                'После setModalState _radiusKm: $_radiusKm',
                              );
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Текущий радиус: ${_radiusKm.round()} км (значение: $_radiusKm)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.gray,
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Кнопки Применить и Сбросить
                    Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: Btn(
                            text: 'Сбросить',
                            theme: 'gray',
                            onPressed:
                                () => _resetFiltersInModal(setModalState),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Btn(
                            text: 'Применить',
                            theme: 'violet',
                            onPressed: _applyFilters,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
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
