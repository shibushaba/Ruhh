import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/features/prayer/islamic_app_service.dart';
import 'package:ruhh/features/prayer/prayer_repository.dart';
import 'package:ruhh/features/prayer/sunrise_sunset_service.dart';
import 'package:ruhh/features/prayer/telawa_service.dart';

final telawaServiceProvider = Provider((ref) => TelawaService());
final islamicAppServiceProvider = Provider((ref) => IslamicAppService());
final sunriseSunsetServiceProvider = Provider((ref) => SunriseSunsetService());

/// Prefer Telawa; fall back to islamic.app.
final dailyAyahProvider = FutureProvider<DailyAyah?>((ref) async {
  ref.watch(prayerRefreshProvider);
  final telawa = ref.watch(telawaServiceProvider);
  final islamic = ref.watch(islamicAppServiceProvider);
  var ayah = await telawa.randomAyah() ?? await islamic.randomAyah();
  if (ayah == null) return null;
  if (ayah.textEn == null || ayah.textEn!.trim().isEmpty) {
    final en = await islamic.simpleEnglishForKey(ayah.ayahKey);
    if (en != null && en.isNotEmpty) {
      ayah = DailyAyah(
        ayahKey: ayah.ayahKey,
        textAr: ayah.textAr,
        textEn: en,
        surahNameEn: ayah.surahNameEn,
        source: ayah.source,
      );
    }
  }
  return ayah;
});

final todaySunTimesProvider = FutureProvider<SunTimes?>((ref) async {
  ref.watch(prayerRefreshProvider);
  final repo = await ref.watch(prayerRepositoryProvider.future);
  final (lat, lng) = await repo.location();
  return ref.watch(sunriseSunsetServiceProvider).forLocation(
        latitude: lat,
        longitude: lng,
      );
});
