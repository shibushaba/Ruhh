import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/data/models/movie_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/features/movie/movie_repository.dart';
import 'package:ruhh/features/movie/widgets/movie_poster_card.dart';

class MovieLibraryPage extends ConsumerWidget {
  const MovieLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(movieRefreshProvider);
    final repoAsync = ref.watch(movieRepositoryProvider);

    return repoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (repo) => StreamBuilder<List<MovieLocal>>(
        stream: repo.watchLibrary(),
        builder: (context, snap) {
          final all = snap.data ?? [];
          return FutureBuilder<MovieLibraryStats>(
            future: repo.stats(),
            builder: (context, statsSnap) {
              final stats = statsSnap.data;
              return DefaultTabController(
                length: 4,
                child: Column(
                  children: [
                    if (stats != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: NBCard(
                          color: NBColors.movie.withValues(alpha: 0.3),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _StatChip('Watchlist', stats.want),
                              _StatChip('Watching', stats.watching),
                              _StatChip('Watched', stats.watched),
                              _StatChip('Favorites', stats.favorites),
                              _StatChip('Rated', stats.rated),
                            ],
                          ),
                        ),
                      ),
                    const TabBar(
                      isScrollable: true,
                      tabs: [
                        Tab(text: 'Watchlist'),
                        Tab(text: 'Watching'),
                        Tab(text: 'Watched'),
                        Tab(text: 'Favorites'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _Grid(items: all.where((m) => m.watchStatus == WatchStatus.wantToWatch).toList()),
                          _Grid(items: all.where((m) => m.watchStatus == WatchStatus.watching).toList()),
                          _Grid(items: all.where((m) => m.watchStatus == WatchStatus.watched).toList()),
                          _Grid(items: all.where((m) => m.favorite).toList()),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      side: const BorderSide(color: NBColors.black, width: 2),
    );
  }
}

class _Grid extends ConsumerWidget {
  const _Grid({required this.items});

  final List<MovieLocal> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const Center(child: Text('Nothing here yet'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.55,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final m = items[i];
        return Dismissible(
          key: ValueKey(m.remoteId),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red.shade300,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete_outline),
          ),
          confirmDismiss: (_) async {
            final repo = await ref.read(movieRepositoryProvider.future);
            await repo.remove(m);
            bumpMovieRefresh(ref);
            return true;
          },
          child: MoviePosterCard(
            title: m.title,
            posterPath: m.posterPath,
            subtitle: watchStatusLabel(m.watchStatus),
            width: double.infinity,
            onTap: () {
              if (m.tmdbId != null) {
                context.push('/movie/detail/${m.mediaType}/${m.tmdbId}');
              }
            },
          ),
        );
      },
    );
  }
}
