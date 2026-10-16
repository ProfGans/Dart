import 'package:flutter_test/flutter_test.dart';
import 'package:dart_tournament_manager/features/communities/application/challonge_knockout_slots.dart';
import 'package:dart_tournament_manager/features/tournaments/domain/tournament_models.dart';
import 'challonge_native_import_test.dart' show fixture, native;

void main() {
  test('DCUH202603 six qualifiers preserve omitted Friedel and Max byes', () {
    // Actual KO: Marvin beats Kevin, Timo B beats Timo S; Friedel and Max
    // enter the semifinals and Friedel wins the final 2:0.
    final data = fixture(
      'single elimination',
      [
        [1, 4, 5, 2, 1],
        [1, 3, 6, 0, 2],
        [2, 1, 4, 2, 0],
        [2, 2, 6, 2, 0],
        [3, 1, 2, 2, 0],
      ],
      ranks: [1, 2, 5, 3, 5, 3],
    );
    final matches = (data['matches'] as List).cast<Map<String, dynamic>>();
    for (final pair in matches.indexed) {
      pair.$2['identifier'] = pair.$1 + 1;
    }
    matches[2]['player2_prereq_identifier'] = 1;
    matches[3]['player2_prereq_identifier'] = 2;
    matches[4]['player1_prereq_identifier'] = 3;
    matches[4]['player2_prereq_identifier'] = 4;
    expect(challongeKnockoutSlots(matches), [
      '1',
      null,
      '4',
      '5',
      '2',
      null,
      '3',
      '6',
    ]);
    final converted = native(data);
    final run = converted.runStages.single as KnockoutTournamentRunStage;
    expect(converted.completedStageIndexes, [0]);
    expect(run.rounds.last.single.winner?.profileId, 'p1');
    expect(converted.importedArchive!.matches.length, 5);
    expect(converted.importedArchive!.nativeValidation!['status'], 'matched');
  });
}
