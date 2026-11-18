import 'package:flutter/material.dart';

class PetFormName {
  const PetFormName(this.early, this.late);
  final String early;
  final String late;

  String at(int subStage) => subStage <= 1 ? early : late;
}

class PetPack {
  const PetPack({
    required this.id,
    required this.kind,
    required this.defaultName,
    required this.worlds,
    required this.forms,
    required this.accents,
    required this.accents2,
    required this.missingWorlds,
  });

  final String id;
  final String kind;
  final String defaultName;
  final List<String> worlds;
  final List<PetFormName> forms;
  final List<Color> accents;
  final List<Color> accents2;
  final Set<int> missingWorlds;

  bool artMissing(int world) => missingWorlds.contains(world);

  String worldName(int world) => worlds[(world - 1).clamp(0, 4)];

  String formName(int world, int subStage) =>
      forms[(world - 1).clamp(0, 4)].at(subStage);

  Color accent(int world) => accents[(world - 1).clamp(0, 4)];
  Color accent2(int world) => accents2[(world - 1).clamp(0, 4)];
}

const petPacks = <String, PetPack>{
  'dragon': PetPack(
    id: 'dragon',
    kind: 'Dragon',
    defaultName: 'Ruu',
    worlds: [
      'Ember Nest',
      'Moss Ledge',
      'Cliff Shrine',
      'Wind Temple',
      'Star Summit',
    ],
    forms: [
      PetFormName('Ember Egg', 'Hearthling'),
      PetFormName('Mossback', 'Ledgewalker'),
      PetFormName('Bellwing', 'Lanternheart'),
      PetFormName('Windrider', 'Stormhorn'),
      PetFormName('Starbreath', 'Lanternsky'),
    ],
    accents: [
      Color(0xFFF2A23A),
      Color(0xFF7BD389),
      Color(0xFFE2A65C),
      Color(0xFF6CC3E8),
      Color(0xFFF0C75E),
    ],
    accents2: [
      Color(0xFFFFD08A),
      Color(0xFFC9F2A0),
      Color(0xFFF2D3A2),
      Color(0xFFC3E9F7),
      Color(0xFFF6E3A6),
    ],
    missingWorlds: {},
  ),
  'panda': PetPack(
    id: 'panda',
    kind: 'Panda',
    defaultName: 'Sumi',
    worlds: [
      'Bamboo Hollow',
      'Mist Terraces',
      'River Gorge',
      'Plum Cloud',
      'Moon Peak',
    ],
    forms: [
      PetFormName('Cub', 'Cub'),
      PetFormName('Bamboo Scout', 'Bamboo Scout'),
      PetFormName('Mist Walker', 'Mist Walker'),
      PetFormName('Plum Guardian', 'Plum Guardian'),
      PetFormName('Moon Sage', 'Moon Sage'),
    ],
    accents: [
      Color(0xFFD9C08A),
      Color(0xFFA8D5A2),
      Color(0xFF8FC9C2),
      Color(0xFFE3A9C4),
      Color(0xFFE8E2C8),
    ],
    accents2: [
      Color(0xFFF2E2B8),
      Color(0xFFD6EFD1),
      Color(0xFFC9EAE5),
      Color(0xFFF5D5E4),
      Color(0xFFF7F3E3),
    ],
    missingWorlds: {2, 3, 4},
  ),
  'cat': PetPack(
    id: 'cat',
    kind: 'Cat',
    defaultName: 'Kage',
    worlds: [
      'Lantern Alley',
      'Rooftop Gardens',
      'Old Library',
      'Harbor Lights',
      'Starlit Rooftops',
    ],
    forms: [
      PetFormName('Kitten', 'Kitten'),
      PetFormName('Alley Shade', 'Alley Shade'),
      PetFormName('Roof Runner', 'Roof Runner'),
      PetFormName('Harbor Watcher', 'Harbor Watcher'),
      PetFormName('Star Warden', 'Star Warden'),
    ],
    accents: [
      Color(0xFFF2B35E),
      Color(0xFF9CCB86),
      Color(0xFFC9A27A),
      Color(0xFF7FB6D9),
      Color(0xFFA9B9F2),
    ],
    accents2: [
      Color(0xFFFFD9A0),
      Color(0xFFD3EBC6),
      Color(0xFFEBD5BC),
      Color(0xFFC6E2F3),
      Color(0xFFD9E0FB),
    ],
    missingWorlds: {2, 3, 4},
  ),
};

PetPack petPackFor(String? id) => petPacks[id] ?? petPacks['dragon']!;

class HotspotSpec {
  const HotspotSpec({
    required this.id,
    required this.label,
    required this.route,
    required this.x,
    required this.y,
  });
  final String id;
  final String label;
  final String route;
  final double x;
  final double y;
}

List<HotspotSpec> hotspotsFor({required String petId, required int world}) {
  final habits = switch (petId) {
    'panda' => world == 5 ? 'Constellation' : 'Stone lamps',
    'cat' => world == 5 ? 'Constellation' : 'Window candles',
    _ => switch (world) {
      1 => 'Candle ledge',
      2 => 'Stones',
      3 => 'Bell rope',
      4 => 'Chimes',
      _ => 'Constellation',
    },
  };
  final quests = switch (petId) {
    'panda' => world == 5 ? 'Lanterns' : 'Bamboo post',
    'cat' => world == 5 ? 'Lanterns' : 'Notice board',
    _ => switch (world) {
      1 => 'Quest wall',
      2 => 'Leaf post',
      3 => 'Ema rack',
      4 => 'Banners',
      _ => 'Waiting lanterns',
    },
  };
  final goals = switch (petId) {
    'panda' => world == 1 ? 'Lantern' : 'Sky lanterns',
    'cat' => world == 1 ? 'Lantern' : 'Sky lanterns',
    _ => switch (world) {
      1 => 'Lantern',
      2 => 'Bridge lanterns',
      4 => 'Islands',
      5 => 'Sky lanterns',
      _ => 'Stone lanterns',
    },
  };
  return [
    HotspotSpec(id: 'habits', label: habits, route: '/habit', x: 0.22, y: 0.58),
    HotspotSpec(
      id: 'quests',
      label: quests,
      route: '/quests',
      x: 0.78,
      y: 0.46,
    ),
    HotspotSpec(id: 'goals', label: goals, route: '/goals', x: 0.62, y: 0.70),
    if (world == 3)
      const HotspotSpec(
        id: 'bell',
        label: 'Big bell',
        route: '/wrap',
        x: 0.50,
        y: 0.34,
      ),
  ];
}
