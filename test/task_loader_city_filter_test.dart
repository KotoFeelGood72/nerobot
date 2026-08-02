import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nerobot/utils/city_coordinates.dart';

void main() {
  group('City filter readiness', () {
    test('known cities resolve to coordinates', () {
      final moscow = CityCoordinates.getCityCoordinates('Москва');
      final spb = CityCoordinates.getCityCoordinates('Санкт-Петербург');

      expect(moscow, isNotNull);
      expect(spb, isNotNull);
      expect(moscow!.latitude, greaterThan(55));
      expect(spb!.latitude, greaterThan(59));
    });

    test('tasks within 50km of city center are kept', () {
      final moscow = CityCoordinates.getCityCoordinates('Москва')!;
      final near = LatLng(moscow.latitude + 0.1, moscow.longitude);
      final far = LatLng(59.93, 30.33); // СПб

      final distance = Distance();
      final nearM = distance.as(LengthUnit.Meter, moscow, near);
      final farM = distance.as(LengthUnit.Meter, moscow, far);

      expect(nearM <= 50000, isTrue);
      expect(farM <= 50000, isFalse);
    });

    test('5km radius is too tight for typical city districts', () {
      final moscow = CityCoordinates.getCityCoordinates('Москва')!;
      // ~11 км от центра (примерно)
      final district = LatLng(moscow.latitude + 0.1, moscow.longitude);
      final distance = Distance();
      final meters = distance.as(LengthUnit.Meter, moscow, district);

      expect(meters <= 5000, isFalse);
      expect(meters <= 50000, isTrue);
    });
  });
}
