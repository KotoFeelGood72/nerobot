import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:nerobot/utils/city_coordinates.dart';
import 'package:nerobot/utils/push_token_manager.dart';

/// Утилиты для работы с городом пользователя
class UserCityUtils {
  /// Получить выбранный город пользователя из Firestore
  static Future<String?> getUserCity() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        print('⚠️ UID пользователя равен null');
        return null;
      }

      print('Получаем город для пользователя: $uid');
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data();
        print('Данные пользователя: $data');
        
        // Проверяем различные возможные поля для города
        final city = data?['city'] ??
            data?['selectedCity'] ??
            data?['location']?['city'] ??
            data?['userCity'];
        
        print('Найденный город: $city');
        return city;
      } else {
        print('⚠️ Документ пользователя не существует');
      }
    } catch (e) {
      print('Ошибка при получении города пользователя: $e');
    }
    return null;
  }

  /// Получить координаты выбранного города пользователя
  static Future<LatLng?> getUserCityCoordinates() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return null;

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data == null) return null;

      final cityLat = data['city_lat'];
      final cityLng = data['city_lng'];
      if (cityLat != null && cityLng != null) {
        final lat =
            (cityLat is num)
                ? cityLat.toDouble()
                : double.tryParse(cityLat.toString());
        final lng =
            (cityLng is num)
                ? cityLng.toDouble()
                : double.tryParse(cityLng.toString());
        if (lat != null &&
            lng != null &&
            !(lat == 0.0 && lng == 0.0) &&
            lat >= -90 &&
            lat <= 90 &&
            lng >= -180 &&
            lng <= 180) {
          print('Координаты города из профиля: $lat, $lng');
          return LatLng(lat, lng);
        }
      }

      final cityName =
          data['city'] ?? data['selectedCity'] ?? data['location']?['city'];
      if (cityName is! String || cityName.isEmpty) {
        print('⚠️ Город пользователя не найден');
        return null;
      }

      final coordinates = CityCoordinates.getCityCoordinates(cityName);
      if (coordinates != null) {
        print(
          'Найдены координаты для города "$cityName": '
          '${coordinates.latitude}, ${coordinates.longitude}',
        );
      } else {
        print('⚠️ Координаты для города "$cityName" не найдены');
      }
      return coordinates;
    } catch (e) {
      print('Ошибка при получении координат города: $e');
      return null;
    }
  }

  /// Установить выбранный город пользователя в Firestore
  static Future<void> setUserCity(String cityName) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final coords = CityCoordinates.getCityCoordinates(cityName);
      final data = <String, dynamic>{
        'city': cityName,
        'selectedCity': cityName,
      };
      if (coords != null) {
        data['city_lat'] = coords.latitude;
        data['city_lng'] = coords.longitude;
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update(data);

      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      await PushTokenManager.syncTopicsFromUserData(snap.data());
    } catch (e) {
      print('Ошибка при установке города пользователя: $e');
    }
  }

  /// Получить список доступных городов
  static List<String> getAvailableCities() {
    return CityCoordinates.getAvailableCities();
  }
}
