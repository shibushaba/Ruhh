import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import 'package:ruhh/core/data/models/movie_local.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:uuid/uuid.dart';

class MovieRepository {
  MovieRepository(this._isar, this._userId);

  final Isar _isar;
  final String _userId;

  Future<List<MovieLocal>> byStatus(WatchStatus status) => _isar.movieLocals
      .filter()
      .userIdEqualTo(_userId)
      .watchStatusEqualTo(status)
      .sortByAddedAtDesc()
      .findAll();

  Future<void> addManual({
    required String title,
    required WatchStatus status,
    String mediaType = 'movie',
  }) async {
    final m = MovieLocal()
      ..remoteId = const Uuid().v4()
      ..userId = _userId
      ..title = title
      ..watchStatus = status
      ..mediaType = mediaType
      ..addedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.movieLocals.put(m));
  }

  Future<void> addFromTmdb(Map<String, dynamic> item, WatchStatus status) async {
    final m = MovieLocal()
      ..remoteId = const Uuid().v4()
      ..userId = _userId
      ..tmdbId = item['id'] as int?
      ..title = (item['title'] ?? item['name'] ?? 'Untitled') as String
      ..posterPath = item['poster_path'] as String?
      ..overview = item['overview'] as String?
      ..mediaType = item['media_type'] as String? ?? 'movie'
      ..watchStatus = status
      ..addedAt = DateTime.now();
    await _isar.writeTxn(() => _isar.movieLocals.put(m));
  }

  Future<void> setStatus(MovieLocal movie, WatchStatus status) async {
    movie.watchStatus = status;
    await _isar.writeTxn(() => _isar.movieLocals.put(movie));
  }

  Future<List<Map<String, dynamic>>> trending(String type) async {
    final key = dotenv.env['TMDB_API_KEY'];
    if (key == null) return [];
    final uri = Uri.parse(
      'https://api.themoviedb.org/3/trending/$type/week?api_key=$key',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['results'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> searchTmdb(String query) async {
    if (query.trim().isEmpty) return [];
    final key = dotenv.env['TMDB_API_KEY'];
    if (key == null) return [];
    final uri = Uri.parse(
      'https://api.themoviedb.org/3/search/multi?api_key=$key&query=${Uri.encodeQueryComponent(query)}',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>? ?? [];
    return results.cast<Map<String, dynamic>>();
  }

  String posterUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return 'https://image.tmdb.org/t/p/w342$path';
  }

  Future<int> watchedThisMonth() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final all = await _isar.movieLocals
        .filter()
        .userIdEqualTo(_userId)
        .watchStatusEqualTo(WatchStatus.watched)
        .addedAtGreaterThan(start)
        .count();
    return all;
  }
}

final movieRepositoryProvider = FutureProvider<MovieRepository>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) throw StateError('No user');
  return MovieRepository(isar, user.supabaseId ?? user.id.toString());
});
