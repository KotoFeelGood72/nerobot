import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Inputs.dart';
import 'package:nerobot/components/ui/app_form_field.dart';
import 'package:nerobot/components/ui/radius_slider_thumb.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/utils/task_loader.dart';
import 'package:nerobot/utils/user_city_utils.dart';

class TaskFilters extends StatefulWidget {
  final Function(Map<String, dynamic>) onApply;
  final int activeFiltersCount;
  final double initialRadiusKm;

  const TaskFilters({
    super.key,
    required this.onApply,
    this.activeFiltersCount = 0,
    this.initialRadiusKm = defaultSearchRadiusKm,
  });

  @override
  State<TaskFilters> createState() => _TaskFiltersState();
}

class _TaskFiltersState extends State<TaskFilters> {
  final _minPriceController = TextEditingController();
  String? _shiftType;
  late double _radiusKm;
  LatLng? _userLocation;
  bool _locationLoading = true;

  final List<String> _shiftOptions = [
    'За смену',
    'За час',
    'За неделю',
    'За месяц',
  ];

  final List<String> _sortOptions = ['По дате', 'По стоимости'];

  String? _sortBy;

  /// Обновляет UI открытого bottom sheet, если локация догрузилась.
  StateSetter? _modalSetState;

  @override
  void initState() {
    super.initState();
    _radiusKm = widget.initialRadiusKm.clamp(1.0, maxSearchRadiusKm);
    _fetchUserLocation();
  }

  @override
  void didUpdateWidget(covariant TaskFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRadiusKm != widget.initialRadiusKm) {
      _radiusKm = widget.initialRadiusKm.clamp(1.0, maxSearchRadiusKm);
    }
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserLocation() async {
    setState(() => _locationLoading = true);
    final cityCoordinates = await UserCityUtils.getUserCityCoordinates();

    if (!mounted) return;

    if (cityCoordinates != null) {
      _setUserLocation(cityCoordinates);
      return;
    }

    await _getCurrentLocation();
    if (mounted && _userLocation == null) {
      setState(() => _locationLoading = false);
      _modalSetState?.call(() {});
    }
  }

  void _setUserLocation(LatLng location) {
    setState(() {
      _userLocation = location;
      _locationLoading = false;
    });
    _modalSetState?.call(() {});
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      _setUserLocation(LatLng(position.latitude, position.longitude));
    } catch (e) {
      debugPrint('Ошибка при получении текущего местоположения: $e');
      if (mounted) {
        setState(() => _locationLoading = false);
        _modalSetState?.call(() {});
      }
    }
  }

  Future<void> _applyFilters() async {
    if (_userLocation == null) {
      await _fetchUserLocation();
    }

    final filters = <String, dynamic>{
      'minPrice': double.tryParse(_minPriceController.text),
      'shiftType': _shiftType,
      'userLocation': _userLocation,
      'radiusKm': _radiusKm,
      'sortBy': _sortBy,
    };

    debugPrint(
      'apply filters: radiusKm=${filters['radiusKm']} '
      'location=${filters['userLocation']}',
    );

    widget.onApply(filters);
    if (mounted) Navigator.pop(context);
  }

  void _resetFiltersInModal(StateSetter setModalState) {
    setModalState(() {
      _minPriceController.clear();
      _shiftType = null;
      _radiusKm = defaultSearchRadiusKm;
      _sortBy = null;
    });
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            _modalSetState = setModalState;
            return Padding(
              padding: MediaQuery.of(
                context,
              ).viewInsets.add(const EdgeInsets.all(16)),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Фильтры',
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
                                'Тип оплаты',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AppDropdown<String>(
                                value: _shiftType,
                                hint: 'Тип оплаты',
                                items:
                                    _shiftOptions
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
                                'Сортировка',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray,
                                ),
                              ),
                              const SizedBox(height: 4),
                              AppDropdown<String>(
                                value: _sortBy,
                                hint: 'Сортировка',
                                items:
                                    _sortOptions
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
                    _buildRadiusSection(setModalState),
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
    ).whenComplete(() {
      _modalSetState = null;
    });
  }

  Widget _buildRadiusSection(StateSetter setModalState) {
    const min = 1.0;
    const max = maxSearchRadiusKm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Радиус поиска (км)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.gray,
          ),
        ),
        Text(
          _locationLoading
              ? 'Определяем город…'
              : _userLocation == null
              ? 'Город не выбран — укажите город в профиле'
              : 'От центра вашего города',
          style: TextStyle(
            fontSize: 12,
            height: 1.2,
            color:
                _userLocation == null && !_locationLoading
                    ? AppColors.red
                    : AppColors.gray,
          ),
        ),
        const SizedBox(height: 10),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 10,
            activeTrackColor: AppColors.violet,
            inactiveTrackColor: AppColors.border,
            disabledActiveTrackColor: AppColors.violet,
            disabledInactiveTrackColor: AppColors.border,
            thumbColor: AppColors.violet,
            overlayColor: AppColors.violet.withValues(alpha: 0.14),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 28),
            thumbShape: RadiusSliderThumb(value: _radiusKm),
            activeTickMarkColor: Colors.transparent,
            inactiveTickMarkColor: Colors.transparent,
            showValueIndicator: ShowValueIndicator.never,
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: _radiusKm,
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: (value) {
              setModalState(() => _radiusKm = value);
            },
          ),
        ),
      ],
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
            const Text('Фильтры'),
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
