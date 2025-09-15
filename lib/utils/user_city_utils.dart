import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import 'package:nerobot/utils/city_coordinates.dart';

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
    final cityName = await getUserCity();
    if (cityName == null) {
      print('⚠️ Город пользователя не найден');
      return null;
    }

    final coordinates = CityCoordinates.getCityCoordinates(cityName);
    if (coordinates != null) {
      print('Найдены координаты для города "$cityName": ${coordinates.latitude}, ${coordinates.longitude}');
    } else {
      print('⚠️ Координаты для города "$cityName" не найдены');
    }
    return coordinates;
  }

  /// Установить выбранный город пользователя в Firestore
  static Future<void> setUserCity(String cityName) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'city': cityName,
        'selectedCity': cityName,
      });
    } catch (e) {
      print('Ошибка при установке города пользователя: $e');
    }
  }

  /// Получить список доступных городов
  static List<String> getAvailableCities() {
    return CityCoordinates.getAvailableCities();
  }
}
