import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/data/models/movie_category_local.dart';
import 'package:ruhh/core/data/models/movie_local.dart';
import 'package:ruhh/features/movie/movie_repository.dart';
import 'package:ruhh/features/movie/tracker/movie_sort.dart';
import 'package:ruhh/features/movie/widgets/movie_category_display.dart';
import 'package:ruhh/features/movie/widgets/movie_tracker_card.dart';

final watchlistCategoryFilterProvider = StateProvider<String?>((ref) => null);
final watchedCategoryFilterProvider = StateProvider<String?>((ref) => null);

final watchlistMoviesProvider = StreamProvider<List<MovieLocal>>((ref) async* {
  final repo = await ref.watch(movieRepositoryProvider.future);
  yield* repo.watchWatchlist();
});

final watchedMoviesProvider = StreamProvider<List<MovieLocal>>((ref) async* {
  final repo = await ref.watch(movieRepositoryProvider.future);
  yield* repo.watchWatchedList();
});

final movieCategoriesProvider = StreamProvider<List<MovieCategoryLocal>>((ref) async* {
  final repo = await ref.watch(movieRepositoryProvider.future);
  yield* repo.watchCategories();
});

class MovieWatchlistPage extends ConsumerWidget {
  const MovieWatchlistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(watchlistMoviesProvider);
    final catsAsync = ref.watch(movieCategoriesProvider);
    final filter = ref.watch(watchlistCategoryFilterProvider);

    return moviesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (movies) {
        final filtered = filterMoviesByCategory(movies, filter);
        final cats = catsAsync.value ?? [];
        final catMap = {for (final c in cats) c.remoteId: c};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CategoryFilterRow(
              categories: cats.where((c) => !c.isArchived).toList(),
              activeId: filter,
              onSelect: (id) =>
                  ref.read(watchlistCategoryFilterProvider.notifier).state = id,
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyWatchlist(hasFilter: filter != null)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final movie = filtered[index];
                        return MovieTrackerCard(
                          movie: movie,
                          category: catMap[movie.categoryRemoteId],
                          primarySwipeLabel: 'Watched',
                          primarySwipeIcon: Icons.check,
                          onMarkPrimary: () => _markWatched(context, ref, movie),
                          onEdit: () => context.push('/movie/edit/${movie.remoteId}'),
                          onDelete: () => _delete(context, ref, movie),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markWatched(
    BuildContext context,
    WidgetRef ref,
    MovieLocal movie,
  ) async {
    final repo = await ref.read(movieRepositoryProvider.future);
    await repo.markWatched(movie);
    if (!context.mounted) return;
    showMovieUndoSnackBar(
      context,
      message: 'Marked as watched',
      onUndo: () async {
        final r = await ref.read(movieRepositoryProvider.future);
        await r.undoMarkWatched(movie);
      },
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    MovieLocal movie,
  ) async {
    if (!await confirmDeleteMovie(context)) return;
    final repo = await ref.read(movieRepositoryProvider.future);
    await repo.remove(movie);
  }
}

class MovieWatchedPage extends ConsumerWidget {
  const MovieWatchedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(watchedMoviesProvider);
    final catsAsync = ref.watch(movieCategoriesProvider);
    final filter = ref.watch(watchedCategoryFilterProvider);

    return moviesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (movies) {
        final filtered = filterMoviesByCategory(movies, filter);
        final cats = catsAsync.value ?? [];
        final catMap = {for (final c in cats) c.remoteId: c};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CategoryFilterRow(
              categories: cats.where((c) => !c.isArchived).toList(),
              activeId: filter,
              onSelect: (id) =>
                  ref.read(watchedCategoryFilterProvider.notifier).state = id,
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyWatched(hasFilter: filter != null)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final movie = filtered[index];
                        return MovieTrackerCard(
                          movie: movie,
                          category: catMap[movie.categoryRemoteId],
                          subtitle: formatWatchedAgo(movie.watchedAt),
                          primarySwipeLabel: 'Watchlist',
                          primarySwipeIcon: Icons.undo,
                          onMarkPrimary: () =>
                              _moveBack(context, ref, movie),
                          onEdit: () => context.push('/movie/edit/${movie.remoteId}'),
                          onDelete: () => _delete(context, ref, movie),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _moveBack(
    BuildContext context,
    WidgetRef ref,
    MovieLocal movie,
  ) async {
    final repo = await ref.read(movieRepositoryProvider.future);
    await repo.moveToWatchlist(movie);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    MovieLocal movie,
  ) async {
    if (!await confirmDeleteMovie(context)) return;
    final repo = await ref.read(movieRepositoryProvider.future);
    await repo.remove(movie);
  }
}

class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow({
    required this.categories,
    required this.activeId,
    required this.onSelect,
  });

  final List<MovieCategoryLocal> categories;
  final String? activeId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _MovieCategoryFilterChip(
              label: 'All',
              accent: Theme.of(context).colorScheme.onSurface,
              selected: activeId == null,
              onTap: () => onSelect(null),
            ),
          ),
          for (final c in categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _MovieCategoryFilterChip(
                label: c.name,
                accent: movieCategoryAccent(c),
                selected: activeId == c.remoteId,
                onTap: () => onSelect(
                  activeId == c.remoteId ? null : c.remoteId,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MovieCategoryFilterChip extends StatelessWidget {
  const _MovieCategoryFilterChip({
    required this.label,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.28)
                : accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accent,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.labelLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? (accent.computeLuminance() > 0.55
                          ? Colors.black
                          : Colors.white)
                      : theme.labelLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyWatchlist extends StatelessWidget {
  const _EmptyWatchlist({required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          hasFilter
              ? 'No movies in this category on your watchlist.'
              : 'Nothing queued up yet — add a movie you want to watch.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _EmptyWatched extends StatelessWidget {
  const _EmptyWatched({required this.hasFilter});

  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          hasFilter
              ? 'No watched movies in this category yet.'
              : 'Nothing watched yet — swipe right on your watchlist when you finish a title.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
