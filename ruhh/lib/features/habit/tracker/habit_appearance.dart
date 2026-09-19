import 'package:flutter/material.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';

/// Accent palette for habit tiles, rings, and the create/edit form.
const kHabitColorChoices = <Color>[
  Color(0xFFF97316),
  Color(0xFFEF4444),
  Color(0xFFDC2626),
  Color(0xFFEC4899),
  Color(0xFFD946EF),
  Color(0xFFAD1457),
  Color(0xFF7C3AED),
  Color(0xFF6366F1),
  Color(0xFF4527A0),
  Color(0xFF3B82F6),
  Color(0xFF0EA5E9),
  Color(0xFF0891B2),
  Color(0xFF14B8A6),
  Color(0xFF00838F),
  Color(0xFF059669),
  Color(0xFF22C55E),
  Color(0xFF84CC16),
  Color(0xFF65A30D),
  Color(0xFFEAB308),
  Color(0xFFF59E0B),
  Color(0xFFEF6C00),
  Color(0xFFFB923C),
  Color(0xFFA855F7),
  Color(0xFF6A1B9A),
  Color(0xFF546E7A),
  Color(0xFF78716C),
  Color(0xFF475569),
  Color(0xFF94A3B8),
  Color(0xFF000000),
];

List<int> habitPresetColorValues() =>
    kHabitColorChoices.map((c) => c.toARGB32()).toList();

const kHabitIconOptions = <(String id, IconData icon)>[
  ('target', Icons.flag_outlined),
  ('star', Icons.star_outline),
  ('check', Icons.check_circle_outline),
  ('trophy', Icons.emoji_events_outlined),
  ('water', Icons.water_drop_outlined),
  ('coffee', Icons.coffee_outlined),
  ('food', Icons.restaurant_outlined),
  ('nutrition', Icons.eco_outlined),
  ('book', Icons.menu_book_outlined),
  ('school', Icons.school_outlined),
  ('work', Icons.work_outline),
  ('laptop', Icons.laptop_mac_outlined),
  ('write', Icons.edit_note_outlined),
  ('code', Icons.code),
  ('run', Icons.directions_run),
  ('walk', Icons.directions_walk),
  ('bike', Icons.directions_bike),
  ('fitness', Icons.fitness_center_outlined),
  ('sport', Icons.sports_soccer),
  ('swim', Icons.pool_outlined),
  ('yoga', Icons.self_improvement),
  ('meditate', Icons.self_improvement),
  ('meditate', Icons.spa_outlined),
  ('bed', Icons.bedtime_outlined),
  ('heart', Icons.favorite_border),
  ('pill', Icons.medication_outlined),
  ('tooth', Icons.health_and_safety_outlined),
  ('brush', Icons.brush_outlined),
  ('shower', Icons.shower_outlined),
  ('clean', Icons.cleaning_services_outlined),
  ('home', Icons.home_outlined),
  ('plant', Icons.local_florist_outlined),
  ('pet', Icons.pets),
  ('music', Icons.music_note_outlined),
  ('movie', Icons.movie_outlined),
  ('game', Icons.sports_esports_outlined),
  ('camera', Icons.photo_camera_outlined),
  ('chat', Icons.chat_bubble_outline),
  ('people', Icons.people_outline),
  ('phone', Icons.phone_android_outlined),
  ('alarm', Icons.alarm_outlined),
  ('calendar', Icons.calendar_today_outlined),
  ('money', Icons.savings_outlined),
  ('cart', Icons.shopping_cart_outlined),
  ('car', Icons.directions_car_outlined),
  ('flight', Icons.flight_outlined),
  ('lightbulb', Icons.lightbulb_outline),
  ('volunteer', Icons.volunteer_activism_outlined),
  ('language', Icons.translate),
  ('moon', Icons.nightlight_outlined),
  ('sun', Icons.wb_sunny_outlined),
];

IconData habitIconData(String name) {
  for (final option in kHabitIconOptions) {
    if (option.$1 == name) return option.$2;
  }
  return Icons.star_outline;
}

final _legacyHabitIconEmoji = <String, String>{
  'target': '🎯',
  'star': '⭐',
  'check': '✅',
  'trophy': '🏆',
  'water': '💧',
  'coffee': '☕',
  'food': '🍽️',
  'nutrition': '🥗',
  'book': '📚',
  'school': '🎓',
  'work': '💼',
  'laptop': '💻',
  'write': '✍️',
  'code': '💻',
  'run': '🏃',
  'walk': '🚶',
  'bike': '🚴',
  'fitness': '🏋️',
  'sport': '⚽',
  'swim': '🏊',
  'yoga': '🧘',
  'meditate': '🧘',
  'bed': '🛏️',
  'heart': '❤️',
  'pill': '💊',
  'tooth': '🦷',
  'brush': '🪥',
  'shower': '🚿',
  'clean': '🧹',
  'home': '🏠',
  'plant': '🌿',
  'pet': '🐾',
  'music': '🎵',
  'movie': '🎬',
  'game': '🎮',
  'camera': '📷',
  'chat': '💬',
  'people': '👥',
  'phone': '📱',
  'alarm': '⏰',
  'calendar': '📅',
  'money': '💰',
  'cart': '🛒',
  'car': '🚗',
  'flight': '✈️',
  'lightbulb': '💡',
  'volunteer': '🤝',
  'language': '🗣️',
  'moon': '🌙',
  'sun': '☀️',
};

String habitLegacyIconToEmoji(String iconId) {
  return _legacyHabitIconEmoji[iconId] ?? '🎯';
}

bool habitIconIsEmoji(String icon) {
  if (icon.isEmpty) return false;
  if (RegExp(r'^[a-z_]+$').hasMatch(icon)) return false;
  return true;
}

Widget habitIconChip(String icon, Color accent, {double size = 40}) {
  final emoji = habitIconIsEmoji(icon) ? icon : null;
  return RuhhIconChip(
    icon: habitIconIsEmoji(icon) ? Icons.circle_outlined : habitIconData(icon),
    emoji: emoji,
    accent: accent,
    size: size,
  );
}

Color habitColorCheckIcon(Color fill) {
  return fill.computeLuminance() > 0.45 ? Colors.black : Colors.white;
}
