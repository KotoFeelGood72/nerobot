import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nerobot/services/dadata_service.dart';

void main() {
  test('suggestCities parses city name, region and coordinates', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'suggestions.dadata.ru');
      expect(request.headers['Authorization'], startsWith('Token '));
      final body = jsonEncode({
        'suggestions': [
          {
            'value': 'г Новосибирск',
            'data': {
              'city': 'Новосибирск',
              'settlement': null,
              'region_with_type': 'Новосибирская обл',
              'geo_lat': '55.0084',
              'geo_lon': '82.9357',
            },
          },
          {
            'value': 'пгт Новосиб',
            'data': {
              'city': null,
              'settlement': 'Новосиб',
              'region_with_type': 'Тестовая обл',
              'geo_lat': '50.1',
              'geo_lon': '80.2',
            },
          },
        ],
      });
      return http.Response.bytes(utf8.encode(body), 200, headers: {
        'content-type': 'application/json; charset=utf-8',
      });
    });

    final service = DadataService(client: client, apiKey: 'test-token');
    final items = await service.suggestCities('Новосиб');

    expect(items, hasLength(2));
    expect(items.first.name, 'Новосибирск');
    expect(items.first.region, 'Новосибирская обл');
    expect(items.first.lat, closeTo(55.0084, 0.0001));
    expect(items.first.lng, closeTo(82.9357, 0.0001));
    expect(items[1].name, 'Новосиб');
  });

  test('suggestCities returns empty for short query', () async {
    final service = DadataService(
      client: MockClient((request) async => http.Response('{}', 200)),
      apiKey: 'test-token',
    );
    expect(await service.suggestCities('Н'), isEmpty);
  });
}
