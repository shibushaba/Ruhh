class V14Destination {
  const V14Destination({
    required this.id,
    required this.label,
    required this.route,
    this.subs = const [],
  });

  final String id;
  final String label;
  final String route;
  final List<V14Destination> subs;
}

const v14Destinations = <V14Destination>[
  V14Destination(
    id: 'home',
    label: 'Home',
    route: '/home',
    subs: [
      V14Destination(id: 'journey', label: 'Journey', route: '/journey'),
      V14Destination(id: 'chat', label: 'Chat', route: '/chat'),
      V14Destination(id: 'settings', label: 'Settings', route: '/settings'),
    ],
  ),
  V14Destination(
    id: 'prayer',
    label: 'Prayer',
    route: '/prayer',
    subs: [
      V14Destination(id: 'prayer-sky', label: 'Sky', route: '/prayer'),
      V14Destination(id: 'prayer-stats', label: 'Stats', route: '/prayer/full'),
      V14Destination(id: 'planner', label: 'Planner', route: '/planner'),
    ],
  ),
  V14Destination(
    id: 'money',
    label: 'Money',
    route: '/budget',
    subs: [
      V14Destination(id: 'money-month', label: 'This month', route: '/budget'),
      V14Destination(id: 'money-add', label: 'Add spend', route: '/budget/add'),
      V14Destination(
        id: 'money-cats',
        label: 'Categories',
        route: '/budget/ledger',
      ),
    ],
  ),
  V14Destination(
    id: 'habits',
    label: 'Habits & Quests',
    route: '/habit',
    subs: [
      V14Destination(id: 'orbit', label: 'Orbit', route: '/habit'),
      V14Destination(id: 'quests', label: 'Quests', route: '/quests'),
      V14Destination(id: 'goals', label: 'Goals', route: '/goals'),
    ],
  ),
  V14Destination(
    id: 'books',
    label: 'Books',
    route: '/book',
    subs: [
      V14Destination(id: 'shelf', label: 'Shelf', route: '/book'),
      V14Destination(id: 'book-add', label: 'Add book', route: '/book/add'),
      V14Destination(id: 'to-movies', label: 'Movies', route: '/movie'),
    ],
  ),
  V14Destination(
    id: 'movies',
    label: 'Movies',
    route: '/movie',
    subs: [
      V14Destination(id: 'stubs', label: 'Stubs', route: '/movie'),
      V14Destination(id: 'movie-add', label: 'Add', route: '/movie/add'),
      V14Destination(
        id: 'movie-cats',
        label: 'Categories',
        route: '/movie/categories',
      ),
    ],
  ),
];

V14Destination? destinationById(String id) {
  for (final node in v14Destinations) {
    if (node.id == id) return node;
    for (final sub in node.subs) {
      if (sub.id == id) return sub;
    }
  }
  return null;
}

List<V14Destination> listModeRows() {
  return [
    for (final node in v14Destinations) ...[node, ...node.subs],
  ];
}
