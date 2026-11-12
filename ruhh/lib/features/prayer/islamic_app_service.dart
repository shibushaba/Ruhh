import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ruhh/features/prayer/telawa_service.dart';

/// islamic.app API — free, no key (https://api.islamic.app).
class IslamicAppService {
  static const _base = 'https://api.islamic.app/v1';

  /// Saheeh International — short, plain English.
  static const simpleEnglishTranslationId = 20;

  Future<DailyAyah?> randomAyah() async {
    final res = await http.get(
      Uri.parse(
        '$_base/verses/random?translations=$simpleEnglishTranslationId',
      ),
    );
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
      Uri.parse(
        '$_base/verses/by_key/$ayahKey?translations=$simpleEnglishTranslationId',
      ),
    );
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
