import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/features/movie/movie_navigation.dart';
import 'package:ruhh/features/movie/movie_repository.dart';
import 'package:ruhh/features/movie/widgets/movie_carousel.dart';

class MovieHomePage extends ConsumerStatefulWidget {
  const MovieHomePage({super.key});

  @override
  ConsumerState<MovieHomePage> createState() => _MovieHomePageState();
}

class _MovieHomePageState extends ConsumerState<MovieHomePage> {
  List<Map<String, dynamic>> _trending = [];
  List<Map<String, dynamic>> _popularMovies = [];
  List<Map<String, dynamic>> _popularTv = [];
  List<Map<String, dynamic>> _nowPlaying = [];
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
      if (!repo.tmdb.configured) {
        setState(() {
          _error = 'Add TMDB_API_KEY to .env for discover content.';
          _loading = false;
        });
        return;
      }
      final results = await Future.wait([
        repo.tmdb.trendingAll(),
        repo.tmdb.popularMovies(),
        repo.tmdb.popularTv(),
        repo.tmdb.nowPlaying(),
      ]);
      if (!mounted) return;
      setState(() {
        _trending = results[0];
        _popularMovies = results[1];
        _popularTv = results[2];
        _nowPlaying = results[3];
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

  @override
  Widget build(BuildContext context) {
    ref.watch(movieRefreshProvider);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: NBCard(
            color: NBColors.movie.withValues(alpha: 0.25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final hero = _trending.isNotEmpty ? _trending.first : null;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          if (hero != null)
            MovieHeroBanner(
              item: hero,
              onTap: () => openMovieFromTmdb(context, hero),
            ),
          MovieCarousel(
            title: 'Trending',
            items: _trending.take(15).toList(),
            onItemTap: (item) => openMovieFromTmdb(context, item),
          ),
          MovieCarousel(
            title: 'Now playing',
            items: _nowPlaying.take(15).toList(),
            onItemTap: (item) => openMovieFromTmdb(context, item),
          ),
          MovieCarousel(
            title: 'Popular movies',
            items: _popularMovies.take(15).toList(),
            onItemTap: (item) => openMovieFromTmdb(context, item),
          ),
          MovieCarousel(
            title: 'Popular TV',
            items: _popularTv.take(15).toList(),
            onItemTap: (item) => openMovieFromTmdb(context, item),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
