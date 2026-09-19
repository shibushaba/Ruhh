import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/movie_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/features/movie/movie_repository.dart';
import 'package:ruhh/features/movie/tmdb_service.dart';
import 'package:ruhh/features/movie/widgets/movie_log_sheet.dart';

class MovieDetailPage extends ConsumerStatefulWidget {
  const MovieDetailPage({
    super.key,
    required this.mediaType,
    required this.tmdbId,
  });

  final String mediaType;
  final int tmdbId;

  @override
  ConsumerState<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends ConsumerState<MovieDetailPage> {
  Map<String, dynamic>? _detail;
  MovieLocal? _library;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = await ref.read(movieRepositoryProvider.future);
      _library = await repo.byTmdb(widget.tmdbId, widget.mediaType);
      if (!repo.tmdb.configured) {
        setState(() {
          _error = 'TMDB_API_KEY missing';
          _loading = false;
        });
        return;
      }
      final detail = widget.mediaType == 'tv'
          ? await repo.tmdb.tvDetail(widget.tmdbId)
          : await repo.tmdb.movieDetail(widget.tmdbId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Map<String, dynamic> get _item =>
      _detail ??
      {
        'id': widget.tmdbId,
        'media_type': widget.mediaType,
        'title': _library?.title,
        'name': _library?.title,
      };

  @override
  Widget build(BuildContext context) {
    ref.watch(movieRefreshProvider);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _detail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail')),
        body: Center(child: Text(_error!)),
      );
    }

    final title = TmdbService.titleOf(_item);
    final overview = (_detail?['overview'] ?? _library?.overview ?? '') as String;
    final backdrop = (_detail?['backdrop_path'] ?? _library?.backdropPath) as String?;
    final poster = (_detail?['poster_path'] ?? _library?.posterPath) as String?;
    final vote = (_detail?['vote_average'] as num?)?.toDouble() ?? _library?.voteAverage;
    final release = TmdbService.releaseOf(_detail ?? {}) ?? _library?.releaseDate;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (backdrop != null || poster != null)
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: NBColors.black, width: 3),
                image: DecorationImage(
                  image: NetworkImage(
                    TmdbService.posterUrl(backdrop ?? poster, size: 'w780'),
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (release != null) Text('Release: $release'),
          if (vote != null) Text('TMDB ${vote.toStringAsFixed(1)} / 10'),
          if (_library != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'In library · ${watchStatusLabel(_library!.watchStatus)}'
                '${_library!.userRating != null ? ' · You: ${_library!.userRating!.toStringAsFixed(1)}' : ''}',
              ),
            ),
          const SizedBox(height: 12),
          Text(overview.isEmpty ? 'No overview.' : overview),
          const SizedBox(height: 24),
          NBButton(
            label: _library == null ? 'Log to library' : 'Update log',
            color: NBColors.movie,
            onPressed: () async {
              await showMovieLogSheet(
                context,
                ref,
                tmdbItem: _detail ?? _item,
                existing: _library,
              );
              _library = await (await ref.read(movieRepositoryProvider.future))
                  .byTmdb(widget.tmdbId, widget.mediaType);
              setState(() {});
            },
          ),
          if (_library != null) ...[
            const SizedBox(height: 12),
            NBButton(
              label: 'Remove from library',
              color: NBColors.budget,
              onPressed: () async {
                final repo = await ref.read(movieRepositoryProvider.future);
                await repo.remove(_library!);
                bumpMovieRefresh(ref);
                if (mounted) {
                  setState(() => _library = null);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
