import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ruhh/features/prayer/telawa_service.dart';

/// islamic.app API — free, no key (https://api.islamic.app).
class IslamicAppService {
  static const _base = 'https://api.islamic.app/v1';

  /// Saheeh International — short, plain English.
  static const simpleEnglishTranslationId = 20;

  Uri _verseUri(String path, {Map<String, String>? query}) {
    return Uri.parse('$_base/$path').replace(queryParameters: query);
  }

  Future<DailyAyah?> randomAyah() async {
    final res = await http.get(
      _verseUri(
        'verses/random',
        query: {'translations': '$simpleEnglishTranslationId'},
      ),
      headers: const {'Accept': 'application/json', 'User-Agent': 'RUHH/1.0'},
    ).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    final verse = data?['verse'] as Map<String, dynamic>?;
    if (verse == null) return null;
    return DailyAyah(
      ayahKey: (verse['verse_key'] as String?) ?? '',
      textAr: (verse['text_uthmani'] as String?) ?? '',
      textEn: _firstTranslationText(verse),
      source: 'islamic.app',
    );
  }

  /// Simple English for a verse key (e.g. `2:255`), when Telawa has no translation.
  Future<String?> simpleEnglishForKey(String ayahKey) async {
    if (ayahKey.isEmpty) return null;
    final res = await http.get(
      _verseUri(
        'verses/by_key/${Uri.encodeComponent(ayahKey)}',
        query: {'translations': '$simpleEnglishTranslationId'},
      ),
      headers: const {'Accept': 'application/json', 'User-Agent': 'RUHH/1.0'},
    ).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    final verse = data?['verse'] as Map<String, dynamic>?;
    if (verse == null) return null;
    return _firstTranslationText(verse);
  }

  static String? _firstTranslationText(Map<String, dynamic> verse) {
    final list = verse['translations'] as List<dynamic>?;
    if (list == null || list.isEmpty) return null;
    final first = list.first as Map<String, dynamic>?;
    final text = first?['text'] as String?;
    if (text == null || text.trim().isEmpty) return null;
    return text.trim();
  }

  Future<Map<String, dynamic>?> chapter(int id) async {
    final res = await http.get(Uri.parse('$_base/chapters/$id'));
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>?;
  }
}
