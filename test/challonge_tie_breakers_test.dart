import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_tournament_manager/features/communities/data/challonge_ranking_rules.dart';
import 'package:dart_tournament_manager/features/tournaments/domain/tournament_models.dart';
import 'package:dart_tournament_manager/tournament_workspace.dart'
    show ProductionTournamentRuntime;
import 'package:dart_tournament_manager/features/tournaments/presentation/widgets/creation/stage_setup_widgets.dart';
import 'challonge_native_import_test.dart' show fixture, native;
import 'challonge_import_test.dart' show member;
import 'package:dart_tournament_manager/features/communities/application/challonge_import_service.dart';
import 'package:dart_tournament_manager/features/communities/domain/challonge_tournament.dart';

const rules = ['matchWins', 'winsVsTied', 'setWins', 'legsFor'];

class ChallongeTieBreakerPreview extends StatefulWidget {
  const ChallongeTieBreakerPreview({super.key});
  @override
  State<ChallongeTieBreakerPreview> createState() =>
      _ChallongeTieBreakerPreviewState();
}

class _ChallongeTieBreakerPreviewState
    extends State<ChallongeTieBreakerPreview> {
  List<String> selected = List.of(rules);
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GroupTieBreakerSetup(
            tieBreakers: selected,
            onMoveTieBreaker: (index, direction) => setState(() {
              final rule = selected.removeAt(index);
              selected.insert(index + direction, rule);
            }),
            onChangeTieBreakers: (value) => setState(() => selected = value),
          ),
        ),
      ),
    ),
  );
}

void main() {
  test(
    'refresh preserves prior import ID, revision, rights and Elo selection',
    () async {
      final source = ChallongeTournament(
        fixture('single elimination', [
          [1, 1, 2, 2, 0],
        ]),
      );
      var saved = CreatedTournament.fromJson(
        native(
            fixture('single elimination', [
              [1, 1, 2, 2, 0],
            ]),
          ).toJson()
          ..['id'] = 'challonge:club:901:reimport:old'
          ..['syncRevision'] = 7
          ..['access'] = {
            'creatorUserId': 'owner',
            'directorUserIds': ['director'],
            'resultUserIds': [],
            'resultEntryMode': 'directors',
          }
          ..['countsForRanking'] = true
          ..['communityRankingIds'] = ['historic-ranking'],
      );
      final service = ChallongeImportService(
        loadMembers: () async => [
          member('Spieler 1', 'p1'),
          member('Spieler 2', 'p2'),
        ],
        loadTournaments: () async => [saved],
        createMember: (_) async => throw StateError('duplicate member'),
        saveTournament: (t) async => saved = t,
      );
      expect(await service.import('club', [source], useNativeLogic: true), 0);
      expect(
        await service.import(
          'club',
          [source],
          useNativeLogic: true,
          refreshExisting: true,
        ),
        1,
      );
      expect(saved.id, 'challonge:club:901:reimport:old');
      expect(saved.syncRevision, 7);
      expect(saved.access.creatorUserId, 'owner');
      expect(saved.access.directorUserIds, ['director']);
      expect(saved.countsForRanking, isTrue);
      expect(saved.communityRankingIds, ['historic-ranking']);
    },
  );
  test('ranking priorities come from declared Challonge columns', () {
    expect(
      challongeRankingRules('''<table><thead><tr>

      <th class="ranking-1"><span data-title="Spiel Historie: Gewonnen - Verloren - Unentschieden">Spiele G-V-U</span></th>

      <th class="ranking-2"><span data-title="Siege gegen Gegner mit gleichen Punkten">U</span></th>

      <th class="ranking-3"><span data-title="Spiel/Satz gewonnen">Gewinne setzen</span></th>

      <th class="ranking-4"><span data-title="Gesamtzahl an erzielten Punkten">Pkt</span></th>

      </tr></thead></table>'''),
      rules,
    );
  });
  test('real day 6 cohort wins produce all ten official ranks', () {
    final games = <List<int>>[
      [5, 6, 1, 2],
      [2, 9, 2, 0],
      [3, 8, 2, 1],
      [4, 7, 2, 0],
      [10, 1, 0, 2],
      [1, 2, 1, 2],
      [7, 5, 1, 2],
      [8, 4, 0, 2],
      [9, 3, 1, 2],
      [6, 10, 2, 1],
      [5, 8, 2, 0],
      [3, 1, 0, 2],
      [4, 9, 2, 1],
      [10, 2, 0, 2],
      [6, 7, 2, 0],
      [9, 5, 0, 2],
      [8, 6, 2, 0],
      [7, 10, 1, 2],
      [1, 4, 2, 0],
      [2, 3, 2, 0],
      [4, 2, 2, 0],
      [10, 3, 2, 0],
      [5, 1, 0, 2],
      [6, 9, 2, 0],
      [7, 8, 2, 1],
      [8, 10, 2, 1],
      [9, 7, 1, 2],
      [1, 6, 2, 0],
      [2, 5, 2, 0],
      [3, 4, 2, 0],
      [10, 4, 2, 1],
      [5, 3, 1, 2],
      [6, 2, 0, 2],
      [7, 1, 0, 2],
      [8, 9, 0, 2],
      [1, 8, 2, 0],
      [9, 10, 0, 2],
      [2, 7, 2, 0],
      [3, 6, 2, 0],
      [4, 5, 2, 1],
      [7, 3, 2, 1],
      [6, 4, 2, 1],
      [10, 5, 0, 2],
      [8, 2, 0, 2],
      [9, 1, 0, 2],
    ];
    final data = fixture(
      'round robin',
      [
        for (final e in games.indexed) [e.$1 ~/ 5 + 1, ...e.$2],
      ],
      ranks: [2, 1, 3, 5, 6, 4, 8, 9, 10, 7],
    );
    for (final match in data['matches'] as List) {
      match['ranking_rules'] = rules;
    }
    final converted = native(data);
    expect(converted.stages.single.groupTieBreakers, rules);
    final group =
        (converted.runStages.single as GroupTournamentRunStage).groups.single;
    final standing = ProductionTournamentRuntime(
      converted,
    ).standings(group, rules);
    expect(standing.map((s) => s.player.profileId), [
      'p2',
      'p1',
      'p3',
      'p6',
      'p4',
      'p5',
      'p10',
      'p7',
      'p8',
      'p9',
    ]);
    expect(converted.importedArchive!.nativeValidation!['status'], 'matched');
  });
  for (final size in [
    const Size(360, 800),
    const Size(800, 600),
    const Size(1440, 900),
  ]) {
    testWidgets('Challonge rule preset selectable at $size with 200% text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var selected = List.of(defaultGroupTieBreakers);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(2)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: GroupTieBreakerSetup(
                      tieBreakers: selected,
                      onMoveTieBreaker: (_, _) {},
                      onChangeTieBreakers: (value) =>
                          setState(() => selected = value),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Challonge-Regeln für Dartgruppen'));
      await tester.pumpAndSettle();
      expect(selected, rules);
      await tester.ensureVisible(find.text('Challonge-Regeln für Swiss'));
      await tester.tap(find.text('Challonge-Regeln für Swiss'));
      await tester.pumpAndSettle();
      expect(selected, [
        'swissPoints',
        'winsVsTied',
        'legsFor',
        'medianBuchholz',
        'legDifference',
      ]);
      expect(tester.takeException(), isNull);
    });
  }
}
