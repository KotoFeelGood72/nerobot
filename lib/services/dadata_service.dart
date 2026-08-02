import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nerobot/config/dadata_config.dart';

class DadataCitySuggestion {
  const DadataCitySuggestion({
    required this.name,
    required this.displayName,
    this.region,
    this.lat,
    this.lng,
  });

  /// Название города/населённого пункта для сохранения в профиль.
  final String name;

  /// Строка для списка подсказок (с регионом).
  final String displayName;

  final String? region;
  final double? lat;
  final double? lng;
}

class DadataService {
  DadataService({http.Client? client, String? apiKey})
    : _client = client ?? http.Client(),
      _apiKey = apiKey ?? DadataConfig.apiKey;

  static const _suggestUrl =
      'https://suggestions.dadata.ru/suggestions/api/4_1/rs/suggest/address';

  final http.Client _client;
  final String _apiKey;

  Future<List<DadataCitySuggestion>> suggestCities(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    if (_apiKey.isEmpty) {
      debugPrint('DaData: API key is not configured');
      return const [];
    }

    final response = await _client.post(
      Uri.parse(_suggestUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Token $_apiKey',
      },
      body: jsonEncode({
        'query': q,
        'count': 10,
        'from_bound': {'value': 'city'},
        'to_bound': {'value': 'settlement'},
        'locations': [
          {'country_iso_code': 'RU'},
        ],
      }),
    );

    if (response.statusCode != 200) {
      debugPrint('DaData error ${response.statusCode}: ${response.body}');
      throw Exception('Не удалось загрузить подсказки города');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final suggestions = decoded['suggestions'] as List<dynamic>? ?? const [];

    final result = <DadataCitySuggestion>[];
    final seen = <String>{};

    for (final item in suggestions) {
      if (item is! Map<String, dynamic>) continue;
      final data = item['data'];
      if (data is! Map<String, dynamic>) continue;

      final city = (data['city'] as String?)?.trim();
      final settlement = (data['settlement'] as String?)?.trim();
      final name = (city != null && city.isNotEmpty) ? city : settlement;
      if (name == null || name.isEmpty) continue;

      final region = (data['region_with_type'] as String?)?.trim();
      final lat = double.tryParse('${data['geo_lat'] ?? ''}');
      final lng = double.tryParse('${data['geo_lon'] ?? ''}');
      final key = '$name|${region ?? ''}|${lat ?? ''}|${lng ?? ''}';
      if (!seen.add(key)) continue;

      final displayName =
          region == null || region.isEmpty ? name : '$name · $region';

      result.add(
        DadataCitySuggestion(
          name: name,
          displayName: displayName,
          region: region,
          lat: lat,
          lng: lng,
        ),
      );
    }

    return result;
  }
}
