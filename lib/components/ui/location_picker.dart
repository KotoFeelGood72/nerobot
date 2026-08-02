import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/config/maps_config.dart';

class LocationPickerMap extends StatefulWidget {
  final LatLng initialLocation;
  final Function(LatLng, String) onLocationSelected;

  const LocationPickerMap({
    required this.initialLocation,
    required this.onLocationSelected,
    super.key,
  });

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  late LatLng _selectedLocation;
  String? _selectedAddress;
  bool _isLoading = false;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    _getAddressFromLatLng(_selectedLocation);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    setState(() => _isLoading = true);

    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (!mounted) return;
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final street = place.street?.trim();
        final locality = place.locality?.trim() ?? place.subAdministrativeArea;
        final parts = [
          if (street != null && street.isNotEmpty) street,
          if (locality != null && locality.isNotEmpty) locality,
        ];
        setState(() {
          _selectedAddress =
              parts.isNotEmpty ? parts.join(', ') : 'Адрес не найден';
        });
      } else {
        setState(() => _selectedAddress = 'Адрес не найден');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _selectedAddress = 'Ошибка получения адреса');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Служба геолокации отключена')),
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Разрешение на геолокацию отклонено')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Геолокация заблокирована')),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    final currentLocation = LatLng(position.latitude, position.longitude);

    setState(() => _selectedLocation = currentLocation);
    _mapController.move(currentLocation, 15);
    _getAddressFromLatLng(currentLocation);
  }

  void _onMapTap(TapPosition _, LatLng point) {
    setState(() => _selectedLocation = point);
    _getAddressFromLatLng(point);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите локацию'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation,
                initialZoom: 13,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: MapsConfig.tileUrl,
                  userAgentPackageName: 'com.sprestay.handyman',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation,
                      width: 48,
                      height: 64,
                      alignment: Alignment.topCenter,
                      child: Image.asset(
                        'assets/icons/map_pin.png',
                        width: 48,
                        height: 64,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© Яндекс.Карты'),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  ),
                if (_selectedAddress != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      _selectedAddress!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: Btn(
                      text: 'Выбрать',
                      theme: 'primary',
                      onPressed: () {
                        final address = _selectedAddress;
                        if (address == null || address.isEmpty) return;
                        widget.onLocationSelected(_selectedLocation, address);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
