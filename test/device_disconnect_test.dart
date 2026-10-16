import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_tournament_manager/features/devices/application/devices_controller.dart';
import 'package:dart_tournament_manager/features/devices/data/board_display_server.dart';
import 'package:dart_tournament_manager/features/devices/domain/board_display.dart';
import 'package:dart_tournament_manager/features/devices/presentation/board_display_view.dart';
import 'package:dart_tournament_manager/features/remote_control/application/remote_host_controller.dart';
import 'package:dart_tournament_manager/features/remote_control/presentation/remote_host_surface.dart';

class DisconnectReceiver extends BoardDisplayServer {
  bool online = false;
  @override
  bool get connected => online;
  void update(bool value, {bool release = false}) {
    online = value;
    if (release) display = null;
    notifyListeners();
  }
}

void main() {
  for (final size in [
    const Size(360, 800),
    const Size(800, 600),
    const Size(1440, 900),
  ]) {
    for (final release in [false, true]) {
      testWidgets(
        'local buttons work after ${release ? 'release' : 'connection loss'} at $size',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final receiver = DisconnectReceiver()
            ..display = const BoardDisplay(
              tournamentId: 'cup',
              tournamentName: 'Cup',
              board: 1,
              state: 'running',
              matchId: 'match',
            );
          final devices = DevicesController(receiver: receiver);
          addTearDown(devices.dispose);
          var taps = 0;
          final host = RemoteHostController();
          addTearDown(host.dispose);
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => RemoteHostSurface(
                controller: host,
                onBack: () {},
                child: AnimatedBuilder(
                  animation: devices,
                  builder: (_, _) => Stack(
                    children: [
                      child!,
                      if (devices.boardPresentation.display != null)
                        Positioned.fill(
                          child: Offstage(
                            offstage: !devices.showDisplay,
                            child: BoardDisplayView(controller: devices),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              home: Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () => taps++,
                    child: const Text('Lokale Aktion'),
                  ),
                ),
              ),
            ),
          );
          receiver.update(true);
          await tester.pumpAndSettle();
          expect(devices.showDisplay, isTrue);
          receiver.update(false, release: release);
          await tester.pumpAndSettle();
          expect(devices.showDisplay, isFalse);
          await tester.tap(find.text('Lokale Aktion'));
          await tester.pump();
          expect(taps, 1);
          receiver
              .notifyListeners(); // Stale assignment must not reactivate the overlay.
          await tester.pump();
          expect(devices.showDisplay, isFalse);
          expect(tester.takeException(), isNull);
        if (!release) {
          receiver.update(true);
          await tester.pump();
          expect(devices.showDisplay, isTrue);
          receiver.update(false);
          await tester.pump();
          await tester.tap(find.text('Lokale Aktion'));
          expect(taps, 2);
        }
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
