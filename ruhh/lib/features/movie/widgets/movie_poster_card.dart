import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/features/movie/tmdb_service.dart';

class MoviePosterCard extends StatelessWidget {
  const MoviePosterCard({
    super.key,
    required this.title,
    this.posterPath,
    this.subtitle,
    this.width = 120,
    this.onTap,
  });

  final String title;
  final String? posterPath;
  final String? subtitle;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final url = TmdbService.posterUrl(posterPath, size: 'w342');
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: width * 1.5,
              decoration: BoxDecoration(
                color: NBColors.movie.withValues(alpha: 0.35),
                border: Border.all(color: NBColors.black, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: NBColors.black,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: url.isEmpty
                  ? const Center(child: Icon(Icons.movie_outlined, size: 36))
                  : Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Center(child: Icon(Icons.broken_image_outlined)),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}
