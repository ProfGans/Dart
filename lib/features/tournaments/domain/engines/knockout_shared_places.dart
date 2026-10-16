import '../tournament_models.dart';

Map<String, int> knockoutSharedPlaces(KnockoutTournamentRunStage stage) {
  if (stage.eliminationLossLimit != 1) return {};
  final ranks = <String, int>{};
  for (final round in stage.rounds) {
    for (final match in round.where((m) => m.hasPlayers && m.isResolved)) {
      final loser = match.loser;
      if (loser != null) {
        ranks[loser.profileId ?? loser.name] = round.length + 1;
      }
    }
  }
  if (stage.rounds.isNotEmpty && stage.rounds.last.length == 1) {
    final winner = stage.rounds.last.single.winner;
    if (winner != null) ranks[winner.profileId ?? winner.name] = 1;
  }
  for (final match in stage.placementMatches) {
    final place =
        match.placementRank ?? (match.label == 'Spiel um Platz 3' ? 3 : null);
    if (place == null || !match.isResolved) continue;
    if (match.winner != null) {
      ranks[match.winner!.profileId ?? match.winner!.name] = place;
    }
    if (match.loser != null) {
      ranks[match.loser!.profileId ?? match.loser!.name] = place + 1;
    }
  }
  return ranks;
}
