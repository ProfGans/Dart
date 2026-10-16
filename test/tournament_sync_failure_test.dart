import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dart_tournament_manager/features/tournaments/data/tournament_storage.dart';
import 'package:dart_tournament_manager/features/tournaments/data/tournament_sync_failure.dart';
import 'package:dart_tournament_manager/features/tournaments/domain/tournament_models.dart';
import 'package:dart_tournament_manager/features/tournaments/domain/imported_tournament_archive.dart';
import 'package:dart_tournament_manager/features/communities/application/challonge_import_service.dart';
import 'package:dart_tournament_manager/features/communities/domain/challonge_tournament.dart';
import 'challonge_import_test.dart' show challongeFixture;

void main() {
  test(
    'a reimported source still prevents duplicate tournaments and member writes',
    () async {
      final source = ChallongeTournament(challongeFixture());
      final saved = CreatedTournament.fromJson(
        source.convert('c', {'1': 'a', '2': 'b', '3': 'c'}).toJson()
          ..['id'] = 'challonge:c:7:reimport:123',
      );
      final service = ChallongeImportService(
        loadMembers: () async => [],
        createMember: (_) async =>
            throw StateError('must not create duplicates'),
        loadTournaments: () async => [saved],
        saveTournament: (_) async =>
            throw StateError('must not save duplicates'),
      );
      expect(await service.import('c', [source]), 0);
    },
  );
  test(
    'deleted source IDs become fresh imports and both pending uploads succeed',
    () async {
      final dir = await Directory.systemTemp.createTemp('deleted-import-');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/tournaments.json');
      final uploaded = <String>[];
      final storage = TournamentStorage(
        file: file,
        currentUserId: () => 'u',
        authorize: (_, _) async {},
        upload: (row) async {
          final id = row['client_tournament_id'] as String;
          if (!id.contains(':reimport:')) {
            throw const PostgrestException(
              message: 'Turnier wurde gelöscht',
              code: 'P0001',
            );
          }
          uploaded.add(id);
        },
      );
      for (final source in ['1', '2']) {
        await storage.saveTournament(
          CreatedTournament(
            id: 'challonge:c:$source',
            name: 'Import $source',
            communityId: 'c',
            players: [],
            stages: [],
            runStages: [],
            importedArchive: ImportedTournamentArchive(
              sourceId: source,
              url: 'https://challonge.com/$source',
              mode: 'round_robin',
              participants: [],
              matches: [],
            ),
          ),
        );
      }
      await storage.synchronize();
      final saved = await storage.loadTournaments();
      expect(saved, hasLength(2));
      expect(saved.map((t) => t.id), everyElement(contains(':reimport:')));
      expect(saved.map((t) => t.importedArchive!.sourceId).toSet(), {'1', '2'});
      expect(uploaded.toSet(), hasLength(2));
      expect(jsonDecode(await file.readAsString())['pending'], isEmpty);
      expect(TournamentStorage.syncStatus.value, 'Synchronisiert');
    },
  );
  test(
    'server rejection is visible and pending import can be retried',
    () async {
      final dir = await Directory.systemTemp.createTemp('rejected-import-');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/tournaments.json');
      var rejected = true;
      final storage = TournamentStorage(
        file: file,
        currentUserId: () => 'u',
        authorize: (_, _) async {},
        upload: (_) async {
          if (rejected) {
            throw const PostgrestException(
              message: 'Keine Erstellberechtigung',
              code: '42501',
            );
          }
        },
      );
      await storage.saveTournament(
        CreatedTournament(
          id: 'challonge:c:1',
          name: 'Import',
          communityId: 'c',
          players: [],
          stages: [],
          runStages: [],
        ),
      );
      await storage.synchronize();
      expect(TournamentStorage.syncStatus.value, contains('42501'));
      expect(
        TournamentStorage.syncStatus.value,
        contains('Keine Erstellberechtigung'),
      );
      expect((await storage.loadTournaments()).single.name, 'Import');
      expect(jsonDecode(await file.readAsString())['pending'], isNotEmpty);
      rejected = false;
      await storage.synchronize();
      expect(jsonDecode(await file.readAsString())['pending'], isEmpty);
      expect(TournamentStorage.syncStatus.value, 'Synchronisiert');
    },
  );
  test(
    'missing function and revision conflicts have specific instructions',
    () {
      expect(
        tournamentSyncFailureMessage(
          const PostgrestException(message: 'missing', code: 'PGRST202'),
        ),
        contains('Servermigrationen'),
      );
      expect(
        tournamentSyncFailureMessage(
          const PostgrestException(message: 'conflict', code: '40001'),
        ),
        contains('Online-Stand laden'),
      );
    },
  );
}
