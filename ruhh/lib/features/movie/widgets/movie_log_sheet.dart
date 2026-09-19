import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/movie_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/features/movie/movie_repository.dart';

Future<void> showMovieLogSheet(
  BuildContext context,
  WidgetRef ref, {
  required Map<String, dynamic> tmdbItem,
  MovieLocal? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      side: BorderSide(color: NBColors.black, width: 3),
      borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
    ),
    builder: (ctx) => _MovieLogSheet(tmdbItem: tmdbItem, existing: existing),
  );
}

class _MovieLogSheet extends ConsumerStatefulWidget {
  const _MovieLogSheet({required this.tmdbItem, this.existing});

  final Map<String, dynamic> tmdbItem;
  final MovieLocal? existing;

  @override
  ConsumerState<_MovieLogSheet> createState() => _MovieLogSheetState();
}

class _MovieLogSheetState extends ConsumerState<_MovieLogSheet> {
  late WatchStatus _status;
  double _rating = 7;
  final _review = TextEditingController();
  bool _liked = false;
  bool _favorite = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _status = e?.watchStatus ?? WatchStatus.wantToWatch;
    _rating = e?.userRating ?? 7;
    _review.text = e?.userReview ?? '';
    _liked = e?.liked ?? false;
    _favorite = e?.favorite ?? false;
  }

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = await ref.read(movieRepositoryProvider.future);
    await repo.logFromTmdb(
      widget.tmdbItem,
      status: _status,
      rating: _rating,
      review: _review.text.trim(),
      liked: _liked,
      favorite: _favorite,
    );
    bumpMovieRefresh(ref);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.tmdbItem['title'] ?? widget.tmdbItem['name'] ?? '') as String;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.paddingOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text('Status', style: Theme.of(context).textTheme.labelLarge),
          Wrap(
            spacing: 8,
            children: WatchStatus.values.map((s) {
              final selected = _status == s;
              return ChoiceChip(
                label: Text(watchStatusLabel(s)),
                selected: selected,
                onSelected: (_) => setState(() => _status = s),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text('Your rating: ${_rating.toStringAsFixed(1)}'),
          Slider(
            value: _rating,
            min: 0,
            max: 10,
            divisions: 20,
            onChanged: (v) => setState(() => _rating = v),
          ),
          NBTextField(controller: _review, label: 'Review (optional)'),
          SwitchListTile(
            title: const Text('Liked'),
            value: _liked,
            onChanged: (v) => setState(() => _liked = v),
          ),
          SwitchListTile(
            title: const Text('Favorite'),
            value: _favorite,
            onChanged: (v) => setState(() => _favorite = v),
          ),
          const SizedBox(height: 8),
          NBButton(
            label: _saving ? 'Saving…' : 'Save to library',
            onPressed: _saving ? null : _save,
            color: NBColors.movie,
          ),
        ],
      ),
    );
  }
}
