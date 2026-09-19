import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/features/movie/tmdb_service.dart';

void openMovieFromTmdb(BuildContext context, Map<String, dynamic> item) {
  final id = item['id'];
  if (id is! int) return;
  final type = TmdbService.mediaTypeOf(item);
  context.push('/movie/detail/$type/$id');
}
