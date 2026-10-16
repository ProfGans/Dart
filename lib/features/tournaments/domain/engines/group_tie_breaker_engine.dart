import '../tournament_models.dart';

class GroupTieBreakerEngine {
  static int compare(
    PlayerStanding a,
    PlayerStanding b,
    List<String> rules,
    List<PlayerStanding> standings,
    List<GroupMatch> matches, {
    Map<TournamentPlayer, num> medianBuchholz = const {},
  }) {
    var cohort = standings.toList();
    for (final rule in rules) {
      num value(PlayerStanding s) => switch (rule) {
        'points' => s.points,
        'swissPoints' => s.points,
        'medianBuchholz' => medianBuchholz[s.player] ?? 0,
        'matchWins' => 2 * s.wins + s.draws,
        'setWins' => s.wins,
        'legDifference' => s.legDifference,
        'legsFor' => s.legsFor,
        'winsVsTied' =>
          matches
              .where(
                (m) =>
                    !m.isDecider &&
                    !m.isAnnulled &&
                    !m.withdrawalIgnored &&
                    m.hasPlayers &&
                    m.hasResult &&
                    m.winner == s.player &&
                    cohort.any((other) => other.player == m.loser),
              )
              .length,
        _ => 0,
      };
      final av = value(a), bv = value(b);
      final comparison = bv.compareTo(av);
      if (comparison != 0) return comparison;
      final next = cohort.where((s) => value(s) == av).toList();
      cohort = next;
    }
    return 0;
  }
}
