import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/station.dart';

/// Talks only to radio-browser.info (station search) — the same, single external
/// endpoint the desktop app uses. No analytics, no other network calls.
class RadioApi {
  static const _hosts = [
    'https://de1.api.radio-browser.info',
    'https://de2.api.radio-browser.info',
    'https://at1.api.radio-browser.info',
    'https://nl1.api.radio-browser.info',
  ];

  Future<List<Station>> search({String? country, String? query, int limit = 60}) async {
    final hosts = List<String>.from(_hosts)..shuffle(Random());
    Object? lastError;
    for (final host in hosts) {
      try {
        final params = <String, String>{
          'limit': '$limit',
          'hidebroken': 'true',
          'order': 'clickcount',
          'reverse': 'true',
        };
        if (country != null && country.isNotEmpty) params['country'] = country;
        if (query != null && query.isNotEmpty) params['name'] = query;

        final uri = Uri.parse('$host/json/stations/search').replace(queryParameters: params);
        final response = await http
            .get(uri, headers: {'User-Agent': 'RadioPlayerAndroid/1.0'})
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as List<dynamic>;
          return data.map((e) => Station.fromJson(e as Map<String, dynamic>)).toList();
        }
      } catch (e) {
        lastError = e;
        continue;
      }
    }
    throw lastError ?? Exception('All API hosts failed');
  }
}
