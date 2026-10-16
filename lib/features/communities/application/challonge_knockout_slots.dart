/// Reconstructs omitted first-round byes from explicit winner prerequisites.
List<String?>? challongeKnockoutSlots(List<Map<String, dynamic>> matches) {
  final winners = matches.where((m) => (m['round'] as int? ?? 0) > 0).toList();
  if (!winners.any(
    (m) =>
        m['player1_prereq_identifier'] != null ||
        m['player2_prereq_identifier'] != null,
  )) {
    return null;
  }
  final byIdentifier = {for (final m in winners) '${m['identifier']}': m};
  final lastRound = winners
      .map((m) => m['round'] as int)
      .reduce((a, b) => a > b ? a : b);
  final roots = winners.where((m) => m['round'] == lastRound).toList();
  if (roots.length != 1 || lastRound > 16) {
    throw const FormatException(
      'K.-o.-Finale nicht eindeutig rekonstruierbar.',
    );
  }
  List<String?> expand(Map<String, dynamic> match) {
    final round = match['round'] as int;
    final width = 1 << (round - 1);
    final slots = <String?>[];
    for (final side in [1, 2]) {
      final prereq = match['player${side}_prereq_identifier'];
      if (prereq != null) {
        final previous = byIdentifier['$prereq'];
        if (previous == null ||
            previous['round'] != round - 1 ||
            match['player${side}_is_prereq_match_loser'] == true ||
            previous['winner_id'] != match['player${side}_id']) {
          throw const FormatException(
            'Widersprüchliche K.-o.-Weiterleitung in der Quelle.',
          );
        }
        slots.addAll(expand(previous));
      } else {
        slots.add(match['player${side}_id']?.toString());
        slots.addAll(List<String?>.filled(width - 1, null));
      }
    }
    return slots;
  }

  return expand(roots.single);
}
