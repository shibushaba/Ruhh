class UndoTicket {
  UndoTicket({
    required this.id,
    required this.label,
    required this.until,
    required this.revert,
  });

  final String id;
  final String label;
  final DateTime until;
  final Future<void> Function() revert;

  bool alive(DateTime now) => now.isBefore(until);
}

class UndoBuffer {
  UndoTicket? current;

  UndoTicket push({
    required String label,
    required DateTime now,
    required Future<void> Function() revert,
    Duration window = const Duration(seconds: 5),
  }) {
    final ticket = UndoTicket(
      id: '${now.microsecondsSinceEpoch}-$label',
      label: label,
      until: now.add(window),
      revert: revert,
    );
    current = ticket;
    return ticket;
  }

  Future<bool> undo(String id, DateTime now) async {
    final ticket = current;
    if (ticket == null || ticket.id != id || !ticket.alive(now)) return false;
    current = null;
    await ticket.revert();
    return true;
  }

  void expire(DateTime now) {
    final ticket = current;
    if (ticket != null && !ticket.alive(now)) current = null;
  }
}
