import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';

class PrayerSettingsPage extends ConsumerStatefulWidget {
  const PrayerSettingsPage({super.key});

  @override
  ConsumerState<PrayerSettingsPage> createState() =>
      _PrayerSettingsPageState();
}

class _PrayerSettingsPageState extends ConsumerState<PrayerSettingsPage> {
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  var _loading = false;
  String? _syncMessage;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final r = await ref.read(prayerRepositoryProvider.future);
    final (lat, lng) = await r.location();
    _latCtrl.text = lat.toStringAsFixed(6);
    _lngCtrl.text = lng.toStringAsFixed(6);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(prayerRefreshProvider);
    final repoAsync = ref.watch(prayerRepositoryProvider);
    return repoAsync.when(
      data: (r) => FutureBuilder(
        future: Future.wait([
          r.hasSyncedTimes(),
          r.dailyReminderEnabled(),
          r.dailyReminderTime(),
          r.postPrayerReminderEnabled(),
          r.postPrayerDelayMinutes(),
        ]),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final synced = snap.data![0] as bool;
          var dailyOn = snap.data![1] as bool;
          var dailyTime = snap.data![2] as String;
          var postOn = snap.data![3] as bool;
          var postDelay = snap.data![4] as int;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Prayer settings',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              NBCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Location (Aladhan sync)',
                        style: Theme.of(context).textTheme.titleMedium),
                    TextField(
                      controller: _latCtrl,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _lngCtrl,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    NBButton(
                      label: synced ? 'Re-sync prayer times' : 'Sync prayer times',
                      color: synced ? NBColors.budget : NBColors.prayer,
                      onPressed: _loading
                          ? null
                          : () async {
                              setState(() {
                                _loading = true;
                                _syncMessage = null;
                              });
                              try {
                                final lat = double.parse(_latCtrl.text);
                                final lng = double.parse(_lngCtrl.text);
                                await r.saveLocation(lat, lng);
                                final n = await r.syncPrayerTimes();
                                setState(() => _syncMessage =
                                    'Synced $n times for ${DateTime.now().year}');
                                bumpPrayerRefresh(ref);
                              } catch (e) {
                                setState(() => _syncMessage = '$e');
                              } finally {
                                setState(() => _loading = false);
                              }
                            },
                    ),
                    if (_syncMessage != null) Text(_syncMessage!),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Daily log reminder'),
                subtitle: Text('Notify at $dailyTime'),
                value: dailyOn,
                onChanged: (v) async {
                  await r.setDailyReminderEnabled(v);
                  setState(() => dailyOn = v);
                },
              ),
              ListTile(
                title: const Text('Reminder time'),
                trailing: Text(dailyTime),
                onTap: () async {
                  final parts = dailyTime.split(':');
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: int.tryParse(parts[0]) ?? 0,
                      minute: int.tryParse(parts[1]) ?? 0,
                    ),
                  );
                  if (picked != null) {
                    final s =
                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                    await r.setDailyReminderTime(s);
                    setState(() => dailyTime = s);
                  }
                },
              ),
              SwitchListTile(
                title: const Text('Post-prayer reminder'),
                subtitle: Text('$postDelay min after each prayer time'),
                value: postOn,
                onChanged: (v) async {
                  await r.setPostPrayerReminderEnabled(v);
                  setState(() => postOn = v);
                },
              ),
              ListTile(
                title: const Text('Delay after adhan (minutes)'),
                trailing: DropdownButton<int>(
                  value: postDelay,
                  items: [5, 10, 15, 20, 30]
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text('$m'),
                          ))
                      .toList(),
                  onChanged: (v) async {
                    if (v == null) return;
                    await r.setPostPrayerDelayMinutes(v);
                    setState(() => postDelay = v);
                  },
                ),
              ),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}
