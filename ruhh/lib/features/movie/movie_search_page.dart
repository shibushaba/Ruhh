import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/features/movie/movie_navigation.dart';
import 'package:ruhh/features/movie/movie_repository.dart';
import 'package:ruhh/features/movie/tmdb_service.dart';
import 'package:ruhh/features/movie/widgets/movie_poster_card.dart';

class MovieSearchPage extends ConsumerStatefulWidget {
  const MovieSearchPage({super.key});

  @override
  ConsumerState<MovieSearchPage> createState() => _MovieSearchPageState();
}

class _MovieSearchPageState extends ConsumerState<MovieSearchPage> {
  final _query = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    final repo = await ref.read(movieRepositoryProvider.future);
    final res = await repo.searchTmdb(q);
    if (mounted) {
      setState(() {
        _results = res
            .where((e) {
              final t = e['media_type'] as String?;
              return t == null || t == 'movie' || t == 'tv';
            })
            .toList();
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final configured = ref.watch(movieRepositoryProvider).maybeWhen(
          data: (r) => r.tmdb.configured,
          orElse: () => false,
        );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: NBTextField(
            controller: _query,
            label: 'Search movies & TV',
            hint: 'Title, actor…',
            onChanged: _runSearch,
          ),
        ),
        if (!configured)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Set TMDB_API_KEY in .env to search.'),
          ),
        if (_searching) const LinearProgressIndicator(),
        Expanded(
          child: _results.isEmpty
              ? Center(
                  child: Text(
                    _query.text.isEmpty ? 'Start typing to search' : 'No results',
                    style: TextStyle(color: NBColors.black.withValues(alpha: 0.6)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = _results[i];
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: NBColors.black, width: 2),
                      ),
                      leading: SizedBox(
                        width: 48,
                        child: MoviePosterCard(
                          title: '',
                          posterPath: item['poster_path'] as String?,
                          width: 48,
                        ),
                      ),
                      title: Text(TmdbService.titleOf(item)),
                      subtitle: Text(TmdbService.mediaTypeOf(item).toUpperCase()),
                      onTap: () => openMovieFromTmdb(context, item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
