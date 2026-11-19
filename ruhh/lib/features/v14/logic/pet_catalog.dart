import 'package:flutter/material.dart';
import 'package:ruhh/features/v14/art/art_catalog.dart';

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

  String formName(int world, int subStage) {
    final inWorld = (artForms[id] ?? artForms['dragon']!)
        .where((form) => form.world == world)
        .toList();
    if (inWorld.isEmpty) return worlds[(world - 1).clamp(0, 4)];
    final index = (subStage.clamp(0, 3) * (inWorld.length - 1) / 3).round();
    return inWorld[index].name;
  }

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
    missingWorlds: {},
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
    missingWorlds: {},
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
    this.labelSide = 'r',
  });
  final String id;
  final String label;
  final String route;
  final double x;
  final double y;
  final String labelSide;
}

List<HotspotSpec> hotspotsFor({required String petId, required int world}) {
  final scene = artWorldOf(petId, world);
  return [
    for (final pin in scene.pins)
      HotspotSpec(
        id: pin.id,
        label: pin.objectName,
        route: pin.route,
        x: pin.x,
        y: pin.y,
        labelSide: pin.labelSide,
      ),
  ];
}
