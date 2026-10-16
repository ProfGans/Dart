import 'package:html/parser.dart' as html;

/// Reads the declared ranking priority, never infers rules from final ranks.
List<String> challongeRankingRules(String document) {
  final rules = <int, String>{};
  for (final cell in html.parse(document).querySelectorAll('thead th')) {
    final priority = RegExp(
      r'(?:^|\s)ranking-(\d+)(?:\s|$)',
    ).firstMatch(cell.className);
    if (priority == null) continue;
    final text =
        '${cell.querySelector('[data-title]')?.attributes['data-title'] ?? ''} ${cell.text}'
            .toLowerCase();
    final rule =
        text.contains('median-buchholz') || text.contains('median buchholz')
        ? 'medianBuchholz'
        : text.trim() == 'punkte' || text.trim() == 'score'
        ? 'swissPoints'
        : text.contains('minus aufgegebene')
        ? 'legDifference'
        : text.contains('gleichen punkten') ||
              text.contains('tied participants')
        ? 'winsVsTied'
        : text.contains('spiel historie') ||
              text.contains('match record') ||
              text.contains('match w-l') ||
              text.contains('spiele g-v')
        ? 'matchWins'
        : text.contains('spiel/satz gewonnen') ||
              text.contains('game/set wins') ||
              text.contains('set wins')
        ? 'setWins'
        : text.contains('gesamtzahl an erzielten') ||
              text.contains('points scored')
        ? 'legsFor'
        : text.contains('points difference') || text.contains('punktedifferenz')
        ? 'legDifference'
        : null;
    // Unknown ranked columns require the existing comparison warning.
    if (rule == null) return [];
    rules[int.parse(priority.group(1)!)] = rule;
  }
  final keys = rules.keys.toList()..sort();
  return [for (final key in keys) rules[key]!];
}
