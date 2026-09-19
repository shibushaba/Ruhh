import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/features/movie/tmdb_service.dart';
import 'package:ruhh/features/movie/widgets/movie_poster_card.dart';

class MovieCarousel extends StatelessWidget {
  const MovieCarousel({
    super.key,
    required this.title,
    required this.items,
    required this.onItemTap,
  });

  final String title;
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic> item) onItemTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final item = items[i];
              return MoviePosterCard(
                title: TmdbService.titleOf(item),
                posterPath: item['poster_path'] as String?,
                subtitle: TmdbService.releaseOf(item),
                onTap: () => onItemTap(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class MovieHeroBanner extends StatelessWidget {
  const MovieHeroBanner({
    super.key,
    required this.item,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backdrop = item['backdrop_path'] as String?;
    final url = backdrop != null && backdrop.isNotEmpty
        ? TmdbService.posterUrl(backdrop, size: 'w780')
        : TmdbService.posterUrl(item['poster_path'] as String?, size: 'w780');
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: NBColors.movie,
            border: Border.all(color: NBColors.black, width: 3),
            boxShadow: const [
              BoxShadow(
                color: NBColors.shadow,
                offset: NBMetrics.shadowOffset,
                blurRadius: 0,
              ),
            ],
            image: url.isEmpty
                ? null
                : DecorationImage(
                    image: NetworkImage(url),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.35),
                      BlendMode.darken,
                    ),
                  ),
          ),
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.all(16),
          child: Text(
            TmdbService.titleOf(item).toUpperCase(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 8)],
                ),
          ),
        ),
      ),
    );
  }
}
