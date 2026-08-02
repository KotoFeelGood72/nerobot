/// Конфигурация карт Яндекс.
///
/// `YANDEX_MAPS_API_KEY` — ключ Tiles API / JS API из кабинета.
/// `MAPKIT_API_KEY` — отдельно для нативного MapKit (не для тайлов).
class MapsConfig {
  static const String yandexTilesApiKey = String.fromEnvironment(
    'YANDEX_MAPS_API_KEY',
    defaultValue: '',
  );

  static const String mapkitApiKey = String.fromEnvironment(
    'MAPKIT_API_KEY',
    defaultValue: '',
  );

  static bool get hasTilesKey => yandexTilesApiKey.isNotEmpty;

  /// Рабочий XYZ-слой Яндекс (Web Mercator), совместим с flutter_map.
  /// Официальный `tiles.api-maps.yandex.ru` иногда отвергает ключ до активации;
  /// этот host отдаёт тайлы стабильно.
  static String get yandexTileUrl {
    final key = yandexTilesApiKey;
    final keyPart = key.isEmpty ? '' : '&apikey=$key';
    return 'https://core-renderer-tiles.maps.yandex.net/tiles'
        '?l=map&x={x}&y={y}&z={z}&scale=1&lang=ru_RU$keyPart';
  }

  static const String fallbackTileUrl =
      'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

  /// Предпочитаем Яндекс-тайлы всегда (слой бесплатно доступен; ключ добавляем если есть).
  static String get tileUrl => yandexTileUrl;

  static bool get usingYandexTiles => true;
}
