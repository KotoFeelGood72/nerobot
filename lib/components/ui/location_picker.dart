import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerMap extends StatefulWidget {
  final LatLng initialLocation;
  final Function(LatLng, String) onLocationSelected;

  const LocationPickerMap({
    required this.initialLocation,
    required this.onLocationSelected,
    Key? key,
  }) : super(key: key);

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  late LatLng _selectedLocation;
  String? _selectedAddress;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Сразу выставляем переданное initialLocation
    _selectedLocation = widget.initialLocation;
    _getAddressFromLatLng(_selectedLocation);
  }

  Future<void> _getAddressFromLatLng(LatLng location) async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _selectedAddress = "${place.street}, ${place.locality}";
        });
      } else {
        setState(() {
          _selectedAddress = "Адрес не найден";
        });
      }
    } catch (e) {
      setState(() {
        _selectedAddress = "Ошибка получения адреса";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Служба геолокации отключена")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Разрешение на геолокацию отклонено")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Геолокация заблокирована")));
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    LatLng currentLocation = LatLng(position.latitude, position.longitude);

    setState(() {
      _selectedLocation = currentLocation;
    });
    _getAddressFromLatLng(currentLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Выберите локацию"),
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
              options: MapOptions(
                // Используем выбранную локацию из initState
                initialCenter: _selectedLocation,
                initialZoom: 13.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    _selectedLocation = point;
                  });
                  _getAddressFromLatLng(point);
                },
              ),
              children: [
                TileLayer(
                  // Без subdomains, один URL для OSM
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),

          if (_selectedAddress != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _selectedAddress!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                if (_selectedLocation != null && _selectedAddress != null) {
                  widget.onLocationSelected(
                    _selectedLocation,
                    _selectedAddress!,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text("Выбрать"),
            ),
          ),
        ],
      ),
    );
  }
}
