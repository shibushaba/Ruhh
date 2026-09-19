import 'package:flutter/material.dart';

import 'package:ruhh/core/data/models/prayer_local.dart';



/// Distinct prayer colors — always saturated (not theme B&W accents).

abstract final class PrayerTheme {

  static const fajr = Color(0xFF38BDF8);

  static const dhuhr = Color(0xFFFBBF24);

  static const asr = Color(0xFFFB923C);

  static const maghrib = Color(0xFFF472B6);

  static const isha = Color(0xFFA78BFA);



  static Color accentSolid(PrayerName p) => switch (p) {

        PrayerName.fajr => fajr,

        PrayerName.dhuhr => dhuhr,

        PrayerName.asr => asr,

        PrayerName.maghrib => maghrib,

        PrayerName.isha => isha,

      };



  /// Slightly softer fill for chips and calendar cells.

  static Color accent(PrayerName p) => accentSolid(p).withValues(alpha: 0.85);



  static Color chipFill(PrayerName p) =>

      accentSolid(p).withValues(alpha: 0.22);



  static Color chipBorder(PrayerName p) => accentSolid(p);



  static Color iconOnAccent(PrayerName p) {

    final c = accentSolid(p);

    return c.computeLuminance() > 0.62 ? Colors.black : Colors.white;

  }



  static String label(PrayerName p) => switch (p) {

        PrayerName.fajr => 'Fajr',

        PrayerName.dhuhr => 'Dhuhr',

        PrayerName.asr => 'Asr',

        PrayerName.maghrib => 'Maghrib',

        PrayerName.isha => 'Isha',

      };



  static IconData icon(PrayerName p) => switch (p) {

        PrayerName.fajr => Icons.wb_twilight,

        PrayerName.dhuhr => Icons.wb_sunny_outlined,

        PrayerName.asr => Icons.wb_cloudy,

        PrayerName.maghrib => Icons.wb_twilight_outlined,

        PrayerName.isha => Icons.nights_stay_outlined,

      };

}


