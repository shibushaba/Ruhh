import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ruhh/core/data/models/movie_category_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_dialog.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/features/movie/movie_repository.dart';
import 'package:ruhh/features/movie/movie_watchlist_page.dart';
import 'package:ruhh/features/movie/tracker/movie_defaults.dart';
import 'package:ruhh/features/movie/widgets/movie_color_picker.dart';
import 'package:ruhh/features/movie/widgets/nb_star_rating.dart';

class MovieFormPage extends ConsumerStatefulWidget {
  const MovieFormPage({super.key, this.remoteId});

  final String? remoteId;

  @override
  ConsumerState<MovieFormPage> createState() => _MovieFormPageState();
}

class _MovieFormPageState extends ConsumerState<MovieFormPage> {
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  int _priority = 3;
  String? _categoryId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = await ref.read(movieRepositoryProvider.future);
    if (widget.remoteId != null) {
      final m = await repo.movieByRemoteId(widget.remoteId!);
      if (m != null) {
        _titleCtrl.text = m.title;
        _noteCtrl.text = m.trackerNote;
        _priority = m.priority.clamp(1, 5);
        _categoryId = m.categoryRemoteId;
      }
    } else {
      final other = await repo.defaultCategory();
      _categoryId = other?.remoteId;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _titleCtrl.text.trim().isNotEmpty &&
      _categoryId != null &&
      _categoryId!.isNotEmpty;

  Future<void> _save() async {
    if (!_canSave) return;
    final repo = await ref.read(movieRepositoryProvider.future);
    await repo.saveTrackerMovie(
      remoteId: widget.remoteId,
      title: _titleCtrl.text,
      priority: _priority,
      categoryRemoteId: _categoryId!,
      note: _noteCtrl.text,
    );
    if (mounted) context.pop();
  }

  Future<void> _newCategory(List<MovieCategoryLocal> active) async {
    final nameCtrl = TextEditingController();
    var color = movieCategoryPalette[active.length % movieCategoryPalette.length];
    if (!mounted) return;
    await showNBStatefulFormDialog(
      context: context,
      title: 'New category',
      content: (_, setLocal) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          NBTextField(controller: nameCtrl, label: 'Name'),
          const SizedBox(height: 12),
          Text('Color', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          MovieColorPalettePicker(
            selected: color,
            onSelected: (c) => setLocal(() => color = c),
          ),
        ],
      ),
      actions: (_, __) => [
        NBDialogAction(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        NBDialogAction(
          label: 'Create',
          primary: true,
          onPressed: () async {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            final repo = await ref.read(movieRepositoryProvider.future);
            final cat = await repo.createCategory(name: name, color: color);
            if (mounted) {
              setState(() => _categoryId = cat.remoteId);
            }
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
    nameCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(movieCategoriesProvider);

    return NBModuleScaffold(
      title: widget.remoteId == null ? 'Add movie' : 'Edit movie',
      glassBackground: false,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NBTextField(
                    controller: _titleCtrl,
                    label: 'Title',
                    hint: 'Movie or show name',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  Text('Priority', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  NBStarRating(
                    value: _priority,
                    onChanged: (v) => setState(() => _priority = v),
                  ),
                  const SizedBox(height: 20),
                  Text('Category', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  catsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('$e'),
                    data: (all) {
                      final active = all.where((c) => !c.isArchived).toList();
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in active)
                            NBChip(
                              label: c.name,
                              selected: _categoryId == c.remoteId,
                              color: Color(c.colorValue),
                              onTap: () => setState(() => _categoryId = c.remoteId),
                            ),
                          NBChip(
                            label: '+ New',
                            selected: false,
                            onTap: () => _newCategory(active),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  NBTextField(
                    controller: _noteCtrl,
                    label: 'Note (optional)',
                    hint: 'Why you want to watch it…',
                  ),
                  const SizedBox(height: 24),
                  NBButton(
                    label: 'Save',
                    color: NBColors.movie,
                    onPressed: _canSave ? _save : null,
                  ),
                ],
              ),
            ),
    );
  }
}
