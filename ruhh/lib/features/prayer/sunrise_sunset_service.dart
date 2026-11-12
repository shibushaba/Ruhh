import 'dart:convert';

import 'package:http/http.dart' as http;

class SunTimes {
  const SunTimes({
    required this.sunrise,
    required this.sunset,
    required this.civilTwilightBegin,
    required this.civilTwilightEnd,
  });

  final DateTime sunrise;
  final DateTime sunset;
  final DateTime civilTwilightBegin;
  final DateTime civilTwilightEnd;
}

/// Sunrise-Sunset.org — free, no key.
class SunriseSunsetService {
  static const _base = 'https://api.sunrise-sunset.org/json';

  Future<SunTimes?> forLocation({
    required double latitude,
    required double longitude,
    DateTime? date,
  }) async {
    final d = date ?? DateTime.now();
    final uri = Uri.parse(_base).replace(queryParameters: {
      'lat': latitude.toString(),
      'lng': longitude.toString(),
      'formatted': '0',
      'date':
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['status'] != 'OK') return null;
    final r = body['results'] as Map<String, dynamic>;
    DateTime? parse(String key) {
      final raw = r[key] as String?;
      if (raw == null) return null;
      return DateTime.tryParse(raw)?.toLocal();
    }

    final sunrise = parse('sunrise');
    final sunset = parse('sunset');
    final dawn = parse('civil_twilight_begin');
    final dusk = parse('civil_twilight_end');
    if (sunrise == null || sunset == null || dawn == null || dusk == null) {
      return null;
    }
    return SunTimes(
      sunrise: sunrise,
      sunset: sunset,
      civilTwilightBegin: dawn,
      civilTwilightEnd: dusk,
    );
  }
}
