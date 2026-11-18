/// On-device awards. Prayer, movies, books, and budget never qualify.
abstract final class XpRules {
  static const habit = 8;
  static const quest = 6;
  static const milestone = 40;
  static const goal = 60;
  static const project = 24;

  static const allowed = {'habit', 'quest', 'milestone', 'goal', 'project'};

  static bool allows(String source) => allowed.contains(source);

  static int amountFor(String source) {
    switch (source) {
      case 'habit':
        return habit;
      case 'quest':
        return quest;
      case 'milestone':
        return milestone;
      case 'goal':
        return goal;
      case 'project':
        return project;
      default:
        return 0;
    }
  }
}
