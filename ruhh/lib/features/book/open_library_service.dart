import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenLibraryBook {
  const OpenLibraryBook({
    required this.key,
    required this.title,
    this.author,
    this.coverUrl,
    this.firstPublishYear,
  });

  final String key;
  final String title;
  final String? author;
  final String? coverUrl;
  final int? firstPublishYear;
}

/// Open Library search + covers (no API key).
class OpenLibraryService {
  static const _searchBase = 'https://openlibrary.org/search.json';
  static const coverBase = 'https://covers.openlibrary.org/b/id';

  Future<List<OpenLibraryBook>> search(String query, {int limit = 20}) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final uri = Uri.parse(_searchBase).replace(queryParameters: {
      'q': q,
      'limit': '$limit',
      'fields':
          'key,title,author_name,cover_i,first_publish_year,cover_edition_key',
    });
    final res = await http.get(uri, headers: {
      'User-Agent': 'RUHH/1.0 (personal life tracker)',
    });
    if (res.statusCode != 200) return [];
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final docs = (body['docs'] as List? ?? []).cast<Map<String, dynamic>>();
    return docs.map(_fromDoc).where((b) => b.title.isNotEmpty).toList();
  }

  OpenLibraryBook _fromDoc(Map<String, dynamic> doc) {
    final authors = (doc['author_name'] as List?)?.cast<String>();
    final coverId = doc['cover_i'];
    return OpenLibraryBook(
      key: (doc['key'] as String?) ?? '',
      title: (doc['title'] as String?) ?? '',
      author: authors == null || authors.isEmpty ? null : authors.first,
      coverUrl: coverId is int ? '$coverBase/$coverId-M.jpg' : null,
      firstPublishYear: doc['first_publish_year'] as int?,
    );
  }
}
