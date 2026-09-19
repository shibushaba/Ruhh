import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/features/movie/movie_navigation.dart';
import 'package:ruhh/features/movie/movie_repository.dart';
import 'package:ruhh/features/movie/widgets/movie_poster_card.dart';
import 'package:ruhh/features/movie/tmdb_service.dart';

class MovieDiscoverPage extends ConsumerStatefulWidget {
  const MovieDiscoverPage({super.key});

  @override
  ConsumerState<MovieDiscoverPage> createState() => _MovieDiscoverPageState();
}

class _MovieDiscoverPageState extends ConsumerState<MovieDiscoverPage> {
  bool _tv = false;
  int? _genreId;
  String _sort = 'popularity.desc';
  List<Map<String, dynamic>> _genres = [];
  List<Map<String, dynamic>> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final repo = await ref.read(movieRepositoryProvider.future);
    if (!repo.tmdb.configured) {
      setState(() => _loading = false);
      return;
    }
    _genres = _tv ? await repo.tmdb.tvGenres() : await repo.tmdb.movieGenres();
    await _discover();
  }

  Future<void> _discover() async {
    setState(() => _loading = true);
    final repo = await ref.read(movieRepositoryProvider.future);
    final list = _tv
        ? await repo.tmdb.discoverTv(
            sortBy: _sort,
            genreId: _genreId,
          )
        : await repo.tmdb.discoverMovies(
            sortBy: _sort,
            genreId: _genreId,
          );
    if (mounted) {
      setState(() {
        _results = list;
        _loading = false;
      });
    }
  }

  Future<void> _setTv(bool tv) async {
    setState(() {
      _tv = tv;
      _genreId = null;
    });
    final repo = await ref.read(movieRepositoryProvider.future);
    _genres = tv ? await repo.tmdb.tvGenres() : await repo.tmdb.movieGenres();
    await _discover();
  }

  @override
  Widget build(BuildContext context) {
    final repoAsync = ref.watch(movieRepositoryProvider);
    return repoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (repo) {
        if (!repo.tmdb.configured) {
          return const Center(child: Text('TMDB_API_KEY missing in .env'));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: NBChip(
                      label: 'Movies',
                      selected: !_tv,
                      onTap: () => _setTv(false),
                      color: NBColors.movie,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: NBChip(
                      label: 'TV',
                      selected: _tv,
                      onTap: () => _setTv(true),
                      color: NBColors.movie,
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: NBChip(
                      label: 'All genres',
                      selected: _genreId == null,
                      onTap: () {
                        _genreId = null;
                        _discover();
                      },
                      color: NBColors.movie,
                    ),
                  ),
                  ..._genres.map((g) {
                    final id = g['id'] as int;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: NBChip(
                        label: g['name'] as String,
                        selected: _genreId == id,
                        onTap: () {
                          _genreId = id;
                          _discover();
                        },
                        color: NBColors.movie,
                      ),
                    );
                  }),
                ],
              ),
            ),
            DropdownButtonFormField<String>(
              value: _sort,
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
              items: const [
                DropdownMenuItem(value: 'popularity.desc', child: Text('Popular')),
                DropdownMenuItem(value: 'vote_average.desc', child: Text('Top rated')),
                DropdownMenuItem(
                  value: 'primary_release_date.desc',
                  child: Text('Newest (movies)'),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                _sort = v;
                _discover();
              },
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.55,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final item = _results[i];
                        return MoviePosterCard(
                          title: TmdbService.titleOf(item),
                          posterPath: item['poster_path'] as String?,
                          width: double.infinity,
                          onTap: () => openMovieFromTmdb(context, item),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
