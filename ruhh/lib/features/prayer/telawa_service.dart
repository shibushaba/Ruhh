import 'dart:convert';

import 'package:http/http.dart' as http;

class DailyAyah {
  const DailyAyah({
    required this.ayahKey,
    required this.textAr,
    required this.source,
    this.surahNameEn,
    this.textEn,
  });

  final String ayahKey;
  final String textAr;
  final String source;
  final String? surahNameEn;
  final String? textEn;
}

/// Telawa Quran API — free, no key (https://telawa.org).
class TelawaService {
  static const _base = 'https://telawa.org/api/v1';

  Future<DailyAyah?> randomAyah() async {
    final res = await http.get(Uri.parse('$_base/ayahs/random'));
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) return null;
    final surah = data['surah'] as Map<String, dynamic>?;
    return DailyAyah(
      ayahKey: (data['ayahKey'] as String?) ?? '',
      textAr: ((data['textAr'] as String?) ?? '').replaceAll('\uFEFF', ''),
      surahNameEn: surah?['nameEn'] as String?,
      source: 'Telawa',
    );
  }
}
