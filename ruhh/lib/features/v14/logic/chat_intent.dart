enum ChatEffect {
  addHabit,
  completeHabit,
  logPrayer,
  addSpend,
  addQuest,
  completeQuest,
  addGoal,
  unknown,
}

class ChatProposal {
  const ChatProposal({
    required this.effect,
    required this.summary,
    required this.grantsXp,
    this.title = '',
    this.amount = 0,
    this.category = '',
  });

  final ChatEffect effect;
  final String summary;
  final bool grantsXp;
  final String title;
  final double amount;
  final String category;

  bool get actionable => effect != ChatEffect.unknown;
}

/// Deterministic, on-device. No network.
ChatProposal parseCompanionUtterance(String raw) {
  final text = raw.trim();
  final lower = text.toLowerCase();
  if (text.isEmpty) {
    return const ChatProposal(
      effect: ChatEffect.unknown,
      summary: 'Say what you want to do.',
      grantsXp: false,
    );
  }

  final prayer = RegExp(
    r'^(?:log |mark )?prayer\s+(fajr|dhuhr|asr|maghrib|isha)$',
    caseSensitive: false,
  ).firstMatch(lower);
  if (prayer != null) {
    final name = prayer.group(1)!;
    return ChatProposal(
      effect: ChatEffect.logPrayer,
      title: name,
      summary: 'Mark $name. Prayer is never scored and earns no XP.',
      grantsXp: false,
    );
  }

  final spend = RegExp(
    r'^(?:spent|spend|add spend)\s+₹?\s*([0-9]+(?:\.[0-9]+)?)\s+(?:on\s+)?(.+)$',
    caseSensitive: false,
  ).firstMatch(text);
  if (spend != null) {
    final amount = double.parse(spend.group(1)!);
    final category = spend.group(2)!.trim();
    return ChatProposal(
      effect: ChatEffect.addSpend,
      amount: amount,
      category: category,
      summary: 'Add ₹${_trim(amount)} to $category. Money never earns XP.',
      grantsXp: false,
    );
  }

  final mapped = _verb(lower, text);
  if (mapped != null) return mapped;

  return ChatProposal(
    effect: ChatEffect.unknown,
    summary:
        'I can add or complete a habit, quest, or goal, log a prayer, or record a spend.',
    grantsXp: false,
  );
}

ChatProposal? _verb(String lower, String original) {
  const table = <(String, ChatEffect, bool)>[
    ('complete habit ', ChatEffect.completeHabit, true),
    ('done habit ', ChatEffect.completeHabit, true),
    ('add habit ', ChatEffect.addHabit, false),
    ('new habit ', ChatEffect.addHabit, false),
    ('complete quest ', ChatEffect.completeQuest, true),
    ('done quest ', ChatEffect.completeQuest, true),
    ('add quest ', ChatEffect.addQuest, false),
    ('new quest ', ChatEffect.addQuest, false),
    ('add goal ', ChatEffect.addGoal, false),
    ('new goal ', ChatEffect.addGoal, false),
  ];
  for (final row in table) {
    if (lower.startsWith(row.$1)) {
      final title = original.substring(row.$1.length).trim();
      if (title.isEmpty) {
        return const ChatProposal(
          effect: ChatEffect.unknown,
          summary: 'That needs a name.',
          grantsXp: false,
        );
      }
      return ChatProposal(
        effect: row.$2,
        title: title,
        grantsXp: row.$3,
        summary: _summary(row.$2, title),
      );
    }
  }
  return null;
}

String _summary(ChatEffect effect, String title) {
  switch (effect) {
    case ChatEffect.addHabit:
      return 'Add habit “$title”. Completing it later can earn XP. Adding it does not.';
    case ChatEffect.completeHabit:
      return 'Mark “$title” done for today. That can earn habit XP.';
    case ChatEffect.addQuest:
      return 'Add quest “$title”.';
    case ChatEffect.completeQuest:
      return 'Mark quest “$title” done. That can earn quest XP.';
    case ChatEffect.addGoal:
      return 'Add goal “$title”.';
    default:
      return title;
  }
}

String _trim(double amount) {
  if (amount == amount.roundToDouble()) return amount.toStringAsFixed(0);
  return amount.toString();
}

abstract class ChatSink {
  Future<void> addHabit(String name);
  Future<void> completeHabit(String name);
  Future<void> logPrayer(String name);
  Future<void> addSpend(double amount, String category);
  Future<void> addQuest(String title);
  Future<void> completeQuest(String title);
  Future<void> addGoal(String title);
}

/// Applies a proposal the person confirmed. Refuses unknown and XP on excluded modules.
Future<void> applyChatProposal(ChatProposal proposal, ChatSink sink) async {
  if (!proposal.actionable) {
    throw StateError('Nothing to apply');
  }
  switch (proposal.effect) {
    case ChatEffect.addHabit:
      await sink.addHabit(proposal.title);
    case ChatEffect.completeHabit:
      await sink.completeHabit(proposal.title);
    case ChatEffect.logPrayer:
      if (proposal.grantsXp) {
        throw StateError('Prayer must not grant XP');
      }
      await sink.logPrayer(proposal.title);
    case ChatEffect.addSpend:
      if (proposal.grantsXp) {
        throw StateError('Money must not grant XP');
      }
      await sink.addSpend(proposal.amount, proposal.category);
    case ChatEffect.addQuest:
      await sink.addQuest(proposal.title);
    case ChatEffect.completeQuest:
      await sink.completeQuest(proposal.title);
    case ChatEffect.addGoal:
      await sink.addGoal(proposal.title);
    case ChatEffect.unknown:
      throw StateError('Nothing to apply');
  }
}
