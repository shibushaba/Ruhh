import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ruhh/features/prayer/telawa_service.dart';

/// islamic.app API — free, no key (https://api.islamic.app).
class IslamicAppService {
  static const _base = 'https://api.islamic.app/v1';

  Future<DailyAyah?> randomAyah() async {
    final res = await http.get(Uri.parse('$_base/verses/random'));
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    final verse = data?['verse'] as Map<String, dynamic>?;
    if (verse == null) return null;
    return DailyAyah(
      ayahKey: (verse['verse_key'] as String?) ?? '',
      textAr: (verse['text_uthmani'] as String?) ?? '',
      source: 'islamic.app',
    );
  }

  Future<Map<String, dynamic>?> chapter(int id) async {
    final res = await http.get(Uri.parse('$_base/chapters/$id'));
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>?;
  }
}
