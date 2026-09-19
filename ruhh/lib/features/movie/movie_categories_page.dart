import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/movie_category_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_dialog.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/features/movie/movie_repository.dart';
import 'package:ruhh/features/movie/movie_watchlist_page.dart';
import 'package:ruhh/features/movie/tracker/movie_defaults.dart';
import 'package:ruhh/features/movie/widgets/movie_color_picker.dart';

class MovieCategoriesPage extends ConsumerWidget {
  const MovieCategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(movieCategoriesProvider);

    return NBModuleScaffold(
      title: 'Categories',
      glassBackground: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _create(context, ref),
        ),
      ],
      body: catsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (cats) {
          final active = cats.where((c) => !c.isArchived).toList();
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: active.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final c = active[index];
              return _CategoryRow(category: c);
            },
          );
        },
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final active = ref.read(movieCategoriesProvider).value ?? [];
    var color = movieCategoryPalette[active.length % movieCategoryPalette.length];
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
          label: 'Save',
          primary: true,
          onPressed: () async {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            final repo = await ref.read(movieRepositoryProvider.future);
            await repo.createCategory(name: name, color: color);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
    nameCtrl.dispose();
  }
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.category});

  final MovieCategoryLocal category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final border = NBColors.glassBorder(Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NBColors.surfaceFill(Theme.of(context).brightness),
        border: Border.all(color: border, width: NBMetrics.borderWidth),
        borderRadius: BorderRadius.circular(NBMetrics.radius),
        boxShadow: const [
          BoxShadow(
            color: NBColors.shadow,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            color: Color(category.colorValue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _edit(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => _archive(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController(text: category.name);
    var color = Color(category.colorValue);
    await showNBStatefulFormDialog(
      context: context,
      title: 'Edit category',
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
          label: 'Save',
          primary: true,
          onPressed: () async {
            final repo = await ref.read(movieRepositoryProvider.future);
            await repo.updateCategory(
              category,
              name: nameCtrl.text,
              color: color,
            );
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ],
    );
    nameCtrl.dispose();
  }

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    final repo = await ref.read(movieRepositoryProvider.future);
    final count = await repo.movieCountForCategory(category.remoteId);
    final ok = await showNBConfirmDialog(
      context: context,
      title: 'Archive category?',
      message: count > 0
          ? '$count movie(s) still use this label. It will be hidden from pickers but stay on those cards.'
          : 'Remove this category from pickers?',
      confirmLabel: 'Archive',
    );
    if (ok != true) return;
    await repo.archiveCategory(category);
  }
}
