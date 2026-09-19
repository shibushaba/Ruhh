import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:ruhh/core/data/models/movie_category_local.dart';
import 'package:ruhh/core/data/models/movie_local.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/nb_dialog.dart';
import 'package:ruhh/features/movie/tracker/movie_defaults.dart';
import 'package:ruhh/features/movie/widgets/movie_category_display.dart';
import 'package:ruhh/features/movie/widgets/nb_star_rating.dart';

class MovieTrackerCard extends StatelessWidget {
  const MovieTrackerCard({
    super.key,
    required this.movie,
    required this.category,
    required this.onMarkPrimary,
    required this.onEdit,
    required this.onDelete,
    required this.primarySwipeLabel,
    required this.primarySwipeIcon,
    this.subtitle,
  });

  final MovieLocal movie;
  final MovieCategoryLocal? category;
  final VoidCallback onMarkPrimary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String primarySwipeLabel;
  final IconData primarySwipeIcon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final theme = Theme.of(context).textTheme;
    final accent = movieCategoryAccent(category);
    final emoji = category != null
        ? movieCategoryEmojiForName(category!.name)
        : '🎬';
    final note = movie.trackerNote.trim();

    final card = Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(t.radiusCardMedium),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(t.radiusCardMedium),
          child: Container(
            decoration: BoxDecoration(
              color: movieCategoryFill(accent, alpha: 0.16),
              borderRadius: BorderRadius.circular(t.radiusCardMedium),
              border: Border(
                left: BorderSide(color: accent, width: 5),
                top: BorderSide(color: accent, width: 1.5),
                right: BorderSide(color: accent, width: 1.5),
                bottom: BorderSide(color: accent, width: 1.5),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(t.spaceCardPaddingCompact),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                        Container(
                          width: 58,
                          height: 86,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius:
                                BorderRadius.circular(t.radiusChip),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movie.title,
                                style: t.cardTitle(theme).copyWith(
                                      fontSize: 17,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle!,
                                  style: t.caption(theme).copyWith(
                                        color: accent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (note.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  note,
                                  style: t.caption(theme),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _CategoryPill(
                                    name: category?.name ?? 'Other',
                                    accent: accent,
                                  ),
                                  const Spacer(),
                                  NBStarRating(
                                    value: movie.priority,
                                    readOnly: true,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    return Slidable(
      key: ValueKey(movie.remoteId),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.28,
        children: [
          SlidableAction(
            onPressed: (_) => onMarkPrimary(),
            backgroundColor: accent,
            foregroundColor: movieCategoryOnAccent(accent),
            icon: primarySwipeIcon,
            label: primarySwipeLabel,
            borderRadius: BorderRadius.circular(t.radiusCardMedium),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.36,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: t.surfaceSecondary,
            foregroundColor: t.textPrimary,
            icon: Icons.edit_outlined,
            label: 'Edit',
            borderRadius: BorderRadius.circular(t.radiusCardMedium),
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Delete',
            borderRadius: BorderRadius.circular(t.radiusCardMedium),
          ),
        ],
      ),
      child: card,
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.name, required this.accent});

  final String name;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(t.radiusChip),
        border: Border.all(color: accent),
      ),
      child: Text(
        name,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

String formatWatchedAgo(DateTime? watchedAt) {
  if (watchedAt == null) return '';
  final diff = DateTime.now().difference(watchedAt);
  if (diff.inDays >= 1) {
    final d = diff.inDays;
    return 'Watched $d day${d == 1 ? '' : 's'} ago';
  }
  if (diff.inHours >= 1) {
    final h = diff.inHours;
    return 'Watched $h hour${h == 1 ? '' : 's'} ago';
  }
  return 'Watched just now';
}

void showMovieUndoSnackBar(
  BuildContext context, {
  required String message,
  required VoidCallback onUndo,
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: onUndo,
      ),
      duration: const Duration(seconds: 4),
    ),
  );
}

Future<bool> confirmDeleteMovie(BuildContext context) async {
  final ok = await showNBConfirmDialog(
    context: context,
    title: 'Delete this movie?',
    message: 'This cannot be undone.',
    confirmLabel: 'Delete',
    destructive: true,
  );
  return ok ?? false;
}
