import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Inputs.dart';
import 'package:nerobot/components/ui/app_form_field.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/utils/user_city_utils.dart';

class TaskFilters extends StatefulWidget {
  final Function(Map<String, dynamic>) onApply;
  final int activeFiltersCount;

  const TaskFilters({
    super.key,
    required this.onApply,
    this.activeFiltersCount = 0,
  });

  @override
  State<TaskFilters> createState() => _TaskFiltersState();
}

class _TaskFiltersState extends State<TaskFilters> {
  final _minPriceController = TextEditingController();
  String? _shiftType;
  double _radiusKm = 50;
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
    print('=== ИНИЦИАЛИЗАЦИЯ TaskFilters ===');
    _fetchUserLocation();
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserLocation() async {
    print('=== ВЫЗОВ _fetchUserLocation ===');
    // Получаем координаты выбранного города пользователя
    final cityCoordinates = await UserCityUtils.getUserCityCoordinates();

    if (mounted) {
      setState(() {
        if (cityCoordinates != null) {
          _userLocation = cityCoordinates;
          print(
            'Установлены координаты города пользователя: ${cityCoordinates.latitude}, ${cityCoordinates.longitude}',
          );
        } else {
          // Если город не найден, используем текущее местоположение как fallback
          _getCurrentLocation();
        }
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
        print(
          'Установлены координаты текущего местоположения: ${position.latitude}, ${position.longitude}',
        );
      }
    } catch (e) {
      print('Ошибка при получении текущего местоположения: $e');
    }
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
    print('=== ПРИМЕНЯЕМ ФИЛЬТРЫ ===');
    print('minPrice: ${filters['minPrice']}');
    print('shiftType: ${filters['shiftType']}');
    print('radiusKm: ${filters['radiusKm']}');
    print('sortBy: ${filters['sortBy']}');
    print('userLocation: ${filters['userLocation']}');
    if (filters['userLocation'] != null) {
      print(
        'Координаты пользователя: ${filters['userLocation'].latitude}, ${filters['userLocation'].longitude}',
      );
    } else {
      print('⚠️ ВНИМАНИЕ: userLocation равен null!');
    }
    print('========================');

    widget.onApply(filters);
    Navigator.pop(context); // Закрыть BottomSheet после применения
  }

  void _resetFilters() {
    if (mounted) {
      setState(() {
        _minPriceController.clear();
        _shiftType = null;
        _radiusKm = 50;
        _sortBy = null;
      });
    }
  }

  void _resetFiltersInModal(StateSetter setModalState) {
    setModalState(() {
      _minPriceController.clear();
      _shiftType = null;
      _radiusKm = 50;
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Inputs(
                      controller: _minPriceController,
                      backgroundColor: AppColors.ulight,
                      textColor: AppColors.gray,
                      label: 'Мин. цена',
                      fieldType: 'number',
                      maxLength: 9,
                    ),

                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Тип оплаты",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AppDropdown<String>(
                                value: _shiftType,
                                hint: "Тип оплаты",
                                items: _shiftOptions
                                    .map(
                                      (label) => DropdownMenuItem<String>(
                                        value: label,
                                        child: Text(label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setModalState(() => _shiftType = value);
                                },
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
                              const SizedBox(height: 4),
                              AppDropdown<String>(
                                value: _sortBy,
                                hint: "Сортировка",
                                items: _sortOptions
                                    .map(
                                      (label) => DropdownMenuItem<String>(
                                        value: label,
                                        child: Text(label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setModalState(() => _sortBy = value);
                                },
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
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const min = 1.0;
                              const max = 50.0;
                              // Горизонтальные отступы трека Slider ≈ половины thumb
                              const sideInset = 24.0;
                              final trackWidth =
                                  (constraints.maxWidth - sideInset)
                                      .clamp(0.0, double.infinity);
                              final t = (_radiusKm - min) / (max - min);
                              final thumbCenterX = sideInset / 2 + t * trackWidth;
                              final label = '${_radiusKm.round()} км';

                              return Column(
                                children: [
                                  SizedBox(
                                    height: 22,
                                    width: double.infinity,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Positioned(
                                          left: (thumbCenterX - 28).clamp(
                                            0.0,
                                            constraints.maxWidth - 56,
                                          ),
                                          child: SizedBox(
                                            width: 56,
                                            child: Text(
                                              label,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.violet,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      showValueIndicator:
                                          ShowValueIndicator.never,
                                    ),
                                    child: Slider(
                                      value: _radiusKm,
                                      min: min,
                                      max: max,
                                      divisions: 49,
                                      activeColor: AppColors.violet,
                                      onChanged: (value) {
                                        setModalState(() => _radiusKm = value);
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Btn(
                            text: 'Сбросить',
                            theme: 'secondary',
                            onPressed:
                                () => _resetFiltersInModal(setModalState),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Btn(
                            text: 'Применить',
                            theme: 'primary',
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
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Фильтры"),
            if (widget.activeFiltersCount > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.violet,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.activeFiltersCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        style: TextButton.styleFrom(foregroundColor: AppColors.violet),
      ),
    );
  }
}
