/// Shipped home plates paint the companion into the scene.
///
/// Overlaying [ArtForm.sprite] on these plates draws a second pet. A future
/// companion-free plate is left out of this set, and the home draws the
/// evolution sprite in that gap. Dragon, Panda, and Cat worlds 1–5 are all
/// painted plates.
const platesWithCompanion = <String>{
  'dragon:1',
  'dragon:2',
  'dragon:3',
  'dragon:4',
  'dragon:5',
  'panda:1',
  'panda:2',
  'panda:3',
  'panda:4',
  'panda:5',
  'cat:1',
  'cat:2',
  'cat:3',
  'cat:4',
  'cat:5',
};

bool platePaintsCompanion(String petId, int world) =>
    platesWithCompanion.contains('$petId:$world');
