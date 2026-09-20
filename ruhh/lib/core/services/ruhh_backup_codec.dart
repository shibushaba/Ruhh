import 'dart:convert';

import 'package:csv/csv.dart';

/// RUHH full-app backup as a single `.csv` file.
///
/// Format: comment header + one [data] section where each row is `key,json`
/// and [json] is a JSON-encoded value (object or array).
class RuhhBackupCodec {
  static const formatVersion = 1;
  static const magic = '#RUHH_BACKUP';

  static String encode(Map<String, dynamic> payload) {
    final metaUsername = payload['source_username'] as String? ?? '';
    final metaExported = payload['exported_at'] as String? ?? '';
    final rows = <List<String>>[
      ['key', 'json'],
      for (final entry in payload.entries)
        [entry.key, jsonEncode(entry.value)],
    ];
    final csvBody = const ListToCsvConverter().convert(rows);
    return [
      '$magic,v$formatVersion',
      '#username,$metaUsername',
      '#exported_at,$metaExported',
      '#section,data',
      csvBody,
    ].join('\n');
  }

  static Map<String, dynamic> decode(String raw) {
    final lines = raw.split(RegExp(r'\r?\n'));
    if (lines.isEmpty || !lines.first.startsWith(magic)) {
      throw FormatException('Not a RUHH backup file (missing $magic header).');
    }

    final versionPart = lines.first.split(',').length > 1
        ? lines.first.split(',').last.replaceFirst('v', '')
        : '';
    final version = int.tryParse(versionPart) ?? 0;
    if (version != formatVersion) {
      throw FormatException(
        'Unsupported backup version $version (expected $formatVersion).',
      );
    }

    final sectionIndex = lines.indexWhere((l) => l.trim() == '#section,data');
    if (sectionIndex < 0 || sectionIndex + 1 >= lines.length) {
      throw FormatException('Backup file is missing the data section.');
    }

    final csvText = lines.sublist(sectionIndex + 1).join('\n').trim();
    if (csvText.isEmpty) {
      throw FormatException('Backup data section is empty.');
    }

    final table = const CsvToListConverter().convert(csvText);
    if (table.isEmpty) {
      throw FormatException('Backup data section is empty.');
    }

    final header = table.first.map((e) => e.toString()).toList();
    final keyIdx = header.indexOf('key');
    final jsonIdx = header.indexOf('json');
    if (keyIdx < 0 || jsonIdx < 0) {
      throw FormatException('Backup data section must have key and json columns.');
    }

    final out = <String, dynamic>{};
    for (var i = 1; i < table.length; i++) {
      final row = table[i];
      if (row.length <= jsonIdx) continue;
      final key = row[keyIdx]?.toString() ?? '';
      if (key.isEmpty) continue;
      final cell = row[jsonIdx]?.toString() ?? '';
      out[key] = jsonDecode(cell);
    }
    return out;
  }
}
