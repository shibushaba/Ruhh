import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/data/models/movie_local.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/core/widgets/nb_text_field.dart';
import 'package:ruhh/features/movie/movie_repository.dart';

class MoviePage extends ConsumerStatefulWidget {
  const MoviePage({super.key});

  @override
  ConsumerState<MoviePage> createState() => _MoviePageState();
}

class _MoviePageState extends ConsumerState<MoviePage> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  WatchStatus _filter = WatchStatus.wantToWatch;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(movieRepositoryProvider);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Movies'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Want'),
              Tab(text: 'Watching'),
              Tab(text: 'Watched'),
            ],
          ),
        ),
        body: repo.when(
          data: (r) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    NBTextField(
                      controller: _search,
                      label: 'Search TMDb',
                      onChanged: (v) async {
                        final res = await r.searchTmdb(v);
                        setState(() => _results = res);
                      },
                    ),
                    if (_results.isNotEmpty)
                      ..._results.take(5).map(
                            (item) => ListTile(
                              title: Text(
                                (item['title'] ?? item['name'] ?? '') as String,
                              ),
                              onTap: () async {
                                await r.addFromTmdb(item, WatchStatus.wantToWatch);
                                setState(() => _results = []);
                                _search.clear();
                              },
                            ),
                          ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: WatchStatus.values.map((status) {
                    return FutureBuilder(
                      future: r.byStatus(status),
                      builder: (context, snap) {
                        final items = snap.data ?? [];
                        if (items.isEmpty) {
                          return const Center(child: Text('Nothing here yet'));
                        }
                        return ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final m = items[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              child: NBCard(
                                color: NBColors.movie.withValues(alpha: 0.3),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(m.title)),
                                    PopupMenuButton<WatchStatus>(
                                      onSelected: (s) async {
                                        await r.setStatus(m, s);
                                        setState(() {});
                                      },
                                      itemBuilder: (_) => WatchStatus.values
                                          .map((s) => PopupMenuItem(
                                                value: s,
                                                child: Text(s.name),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        ),
        floatingActionButton: repo.maybeWhen(
          data: (r) => FloatingActionButton(
            onPressed: () async {
              await r.addManual(
                title: 'Manual entry ${DateTime.now().millisecondsSinceEpoch}',
                status: _filter,
              );
              setState(() {});
            },
            child: const Icon(Icons.add),
          ),
          orElse: () => null,
        ),
      ),
    );
  }
}
