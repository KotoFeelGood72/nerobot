import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nerobot/utils/city_coordinates.dart';
import 'package:nerobot/utils/task_loader.dart';

void main() {
  final nsk = CityCoordinates.getCityCoordinates('Новосибирск')!;

  Map<String, dynamic> task({
    required String id,
    double? lat,
    double? lng,
    String? city,
  }) {
    return {
      'id': id,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (city != null) 'city': city,
    };
  }

  group('filterTasksByRadius', () {
    test('keeps tasks inside radius and drops far ones', () {
      final near = LatLng(nsk.latitude + 0.01, nsk.longitude); // ~1km
      final mid = LatLng(54.9833, 82.8964); // ~3.75km from NSK center
      final far = CityCoordinates.getCityCoordinates('Москва')!;

      final tasks = [
        task(id: 'near', lat: near.latitude, lng: near.longitude),
        task(id: 'mid', lat: mid.latitude, lng: mid.longitude),
        task(id: 'far', lat: far.latitude, lng: far.longitude),
      ];

      final within3 = filterTasksByRadius(
        tasks: tasks,
        center: nsk,
        radiusKm: 3,
      );
      expect(within3.map((t) => t['id']), ['near']);

      final within5 = filterTasksByRadius(
        tasks: tasks,
        center: nsk,
        radiusKm: 5,
      );
      expect(within5.map((t) => t['id']), ['near', 'mid']);
    });

    test('uses city center when task has no coordinates', () {
      final tasks = [
        task(id: 'nsk-no-coords', city: 'Новосибирск'),
        task(id: 'msk-no-coords', city: 'Москва'),
        task(id: 'unknown'),
      ];

      final filtered = filterTasksByRadius(
        tasks: tasks,
        center: nsk,
        radiusKm: 10,
      );

      // Раньше город без координат проходил любой радиус — теперь считается
      // расстояние до центра города.
      expect(filtered.map((t) => t['id']), ['nsk-no-coords']);
    });

    test('does not keep same-city tasks without coords outside radius via name', () {
      // Центр Екатеринбурга далеко от Новосибирска.
      final tasks = [task(id: 'ekb', city: 'Екатеринбург')];

      final filtered = filterTasksByRadius(
        tasks: tasks,
        center: nsk,
        radiusKm: 50,
      );

      expect(filtered, isEmpty);
    });
  });
}
