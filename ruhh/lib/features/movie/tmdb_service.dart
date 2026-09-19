import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// TMDB client (Movie-Tracker reference API surface).
class TmdbService {
  static const _base = 'https://api.themoviedb.org/3';
  static const imageBase = 'https://image.tmdb.org/t/p';

  String? get _key => dotenv.env['TMDB_API_KEY'];

  bool get configured => _key != null && _key!.isNotEmpty;

  Uri _uri(String path, [Map<String, String>? q]) {
    final params = {...?q, 'api_key': _key ?? ''};
    return Uri.parse('$_base$path').replace(queryParameters: params);
  }

  Future<Map<String, dynamic>> _get(String path, [Map<String, String>? q]) async {
    if (!configured) return {};
    final res = await http.get(_uri(path, q));
    if (res.statusCode != 200) return {};
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> _results(Map<String, dynamic> body) =>
      (body['results'] as List? ?? []).cast<Map<String, dynamic>>();

  Future<List<Map<String, dynamic>>> trending(String type, {String window = 'week'}) async {
    final data = await _get('/trending/$type/$window');
    return _results(data);
  }

  Future<List<Map<String, dynamic>>> trendingAll({String window = 'day'}) async {
    final data = await _get('/trending/all/$window');
    return _results(data);
  }

  Future<List<Map<String, dynamic>>> popularMovies() async {
    final data = await _get('/movie/popular');
    return _results(data);
  }

  Future<List<Map<String, dynamic>>> popularTv() async {
    final data = await _get('/tv/popular');
    return _results(data);
  }

  Future<List<Map<String, dynamic>>> topRatedMovies() async {
    final data = await _get('/movie/top_rated');
    return _results(data);
  }

  Future<List<Map<String, dynamic>>> nowPlaying() async {
    final data = await _get('/movie/now_playing');
    return _results(data);
  }

  Future<List<Map<String, dynamic>>> upcoming() async {
    final data = await _get('/movie/upcoming');
    return _results(data);
  }

  Future<List<Map<String, dynamic>>> searchMulti(String query) async {
    if (query.trim().isEmpty) return [];
    final data = await _get('/search/multi', {'query': query.trim()});
    return _results(data);
  }

  Future<List<Map<String, dynamic>>> movieGenres() async {
    final data = await _get('/genre/movie/list');
    return (data['genres'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> tvGenres() async {
    final data = await _get('/genre/tv/list');
    return (data['genres'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> discoverMovies({
    String sortBy = 'popularity.desc',
    int? genreId,
    int? year,
    int page = 1,
  }) async {
    final q = <String, String>{
      'sort_by': sortBy,
      'page': '$page',
    };
    if (genreId != null) q['with_genres'] = '$genreId';
    if (year != null) q['primary_release_year'] = '$year';
    final data = await _get('/discover/movie', q);
    return _results(data);
  }

  Future<List<Map<String, dynamic>>> discoverTv({
    String sortBy = 'popularity.desc',
    int? genreId,
    int? year,
    int page = 1,
  }) async {
    final q = <String, String>{
      'sort_by': sortBy,
      'page': '$page',
    };
    if (genreId != null) q['with_genres'] = '$genreId';
    if (year != null) q['first_air_date_year'] = '$year';
    final data = await _get('/discover/tv', q);
    return _results(data);
  }

  Future<Map<String, dynamic>> movieDetail(int id) async =>
      _get('/movie/$id');

  Future<Map<String, dynamic>> tvDetail(int id) async => _get('/tv/$id');

  static String posterUrl(String? path, {String size = 'w342'}) {
    if (path == null || path.isEmpty) return '';
    return '${TmdbService.imageBase}/$size$path';
  }

  static String titleOf(Map<String, dynamic> item) =>
      (item['title'] ?? item['name'] ?? 'Untitled') as String;

  static String mediaTypeOf(Map<String, dynamic> item) {
    final t = item['media_type'] as String?;
    if (t == 'tv' || t == 'movie') return t!;
    return item['first_air_date'] != null ? 'tv' : 'movie';
  }

  static String? releaseOf(Map<String, dynamic> item) =>
      (item['release_date'] ?? item['first_air_date']) as String?;
}
