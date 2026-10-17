import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/services/sync_triggers.dart';

// testWidgets runs timers on fake time: tester.pump(duration) advances the clock.

class _Harness {
  _Harness({required bool visible, List<ConnectivityResult> startup = const [ConnectivityResult.wifi]})
      : connectivity = StreamController<List<ConnectivityResult>>.broadcast(),
        visibility = StreamController<bool>.broadcast() {
    triggers = SyncTriggers(
      connectivityChanges: connectivity.stream,
      checkConnectivity: () async => startup,
      visibilityChanges: visibility.stream,
      initiallyVisible: visible,
    );
    triggers.signals.listen(signals.add);
  }

  final StreamController<List<ConnectivityResult>> connectivity;
  final StreamController<bool> visibility;
  final List<SyncSignal> signals = [];
  late final SyncTriggers triggers;

  Future<void> dispose() async {
    triggers.dispose();
    await connectivity.close();
    await visibility.close();
  }
}

void main() {
  test('retry waits are 2, 5, 15, 30 seconds, then 60 seconds', () {
    expect(
      [for (var failed = 0; failed < 6; failed++) syncRetryWait(failed)],
      [
        const Duration(seconds: 2),
        const Duration(seconds: 5),
        const Duration(seconds: 15),
        const Duration(seconds: 30),
        const Duration(seconds: 60),
        const Duration(seconds: 60),
      ],
    );
  });

  testWidgets('the network state found at startup is sent once', (tester) async {
    final h = _Harness(visible: true);
    await tester.pump();
    expect(h.signals, [SyncSignal.networkAvailable]);
    await h.dispose();
  });

  testWidgets('no connection at startup is sent as network lost', (tester) async {
    final h = _Harness(visible: true, startup: const [ConnectivityResult.none]);
    await tester.pump();
    expect(h.signals, [SyncSignal.networkLost]);
    await h.dispose();
  });

  testWidgets('network signals are sent only on transitions', (tester) async {
    final h = _Harness(visible: true);
    await tester.pump();
    h.connectivity.add([ConnectivityResult.wifi, ConnectivityResult.mobile]);
    await tester.pump();
    h.connectivity.add([ConnectivityResult.none]);
    await tester.pump();
    h.connectivity.add([ConnectivityResult.none]);
    await tester.pump();
    h.connectivity.add([ConnectivityResult.wifi]);
    await tester.pump();
    expect(h.signals, [
      SyncSignal.networkAvailable,
      SyncSignal.networkLost,
      SyncSignal.networkAvailable,
    ]);
    await h.dispose();
  });

  testWidgets('the interval fires one minute after the armed run while visible and online', (tester) async {
    final h = _Harness(visible: true);
    await tester.pump();
    h.triggers.armInterval();
    await tester.pump(const Duration(seconds: 59));
    expect(h.signals, [SyncSignal.networkAvailable]);
    await tester.pump(const Duration(seconds: 1));
    expect(h.signals.last, SyncSignal.syncIntervalElapsed);
    await h.dispose();
  });

  testWidgets('arming again replaces the pending interval', (tester) async {
    final h = _Harness(visible: true);
    await tester.pump();
    h.triggers.armInterval();
    await tester.pump(const Duration(seconds: 30));
    h.triggers.armInterval();
    await tester.pump(const Duration(seconds: 30));
    expect(h.signals, [SyncSignal.networkAvailable]);
    await tester.pump(const Duration(seconds: 30));
    expect(h.signals.last, SyncSignal.syncIntervalElapsed);
    await h.dispose();
  });

  testWidgets('the interval does not fire while the app is hidden', (tester) async {
    final h = _Harness(visible: true);
    await tester.pump();
    h.visibility.add(false);
    await tester.pump();
    h.triggers.armInterval();
    await tester.pump(const Duration(minutes: 2));
    expect(h.signals, [SyncSignal.networkAvailable]);
    await h.dispose();
  });

  testWidgets('the interval does not fire while offline', (tester) async {
    final h = _Harness(visible: true);
    await tester.pump();
    h.connectivity.add([ConnectivityResult.none]);
    await tester.pump();
    h.triggers.armInterval();
    await tester.pump(const Duration(minutes: 2));
    expect(h.signals, [SyncSignal.networkAvailable, SyncSignal.networkLost]);
    await h.dispose();
  });

  testWidgets('losing the network cancels the armed interval', (tester) async {
    final h = _Harness(visible: true);
    await tester.pump();
    h.triggers.armInterval();
    h.connectivity.add([ConnectivityResult.none]);
    await tester.pump(const Duration(minutes: 2));
    expect(h.signals, [SyncSignal.networkAvailable, SyncSignal.networkLost]);
    await h.dispose();
  });

  testWidgets('the interval does not fire during a retry wait', (tester) async {
    final h = _Harness(visible: true);
    await tester.pump();
    h.triggers.armInterval();
    h.triggers.scheduleRetry(const Duration(seconds: 5));
    expect(h.triggers.retryDueAt, isNotNull);
    await tester.pump(const Duration(seconds: 5));
    expect(h.signals, [SyncSignal.networkAvailable, SyncSignal.syncRetryDue]);
    expect(h.triggers.retryDueAt, isNull);
    await tester.pump(const Duration(minutes: 2));
    expect(h.signals, [SyncSignal.networkAvailable, SyncSignal.syncRetryDue]);
    await h.dispose();
  });

  testWidgets('a scheduled retry is sent when its wait ends and can be cancelled', (tester) async {
    final h = _Harness(visible: true);
    await tester.pump();
    h.triggers.scheduleRetry(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(h.signals, [SyncSignal.networkAvailable]);
    await tester.pump(const Duration(seconds: 1));
    expect(h.signals.last, SyncSignal.syncRetryDue);

    h.triggers.scheduleRetry(const Duration(seconds: 2));
    h.triggers.cancelRetry();
    expect(h.triggers.retryDueAt, isNull);
    await tester.pump(const Duration(seconds: 5));
    expect(h.signals, [SyncSignal.networkAvailable, SyncSignal.syncRetryDue]);
    await h.dispose();
  });

  testWidgets('losing the network cancels a scheduled retry', (tester) async {
    final h = _Harness(visible: true);
    await tester.pump();
    h.triggers.scheduleRetry(const Duration(seconds: 2));
    h.connectivity.add([ConnectivityResult.none]);
    await tester.pump(const Duration(seconds: 3));
    expect(h.signals, [SyncSignal.networkAvailable, SyncSignal.networkLost]);
    expect(h.triggers.retryDueAt, isNull);
    await h.dispose();
  });

  testWidgets('returning to the foreground is sent when the app goes from hidden to visible', (tester) async {
    final h = _Harness(visible: true);
    await tester.pump();
    h.visibility.add(true);
    await tester.pump();
    expect(h.signals, [SyncSignal.networkAvailable]);

    h.visibility.add(false);
    await tester.pump();
    h.visibility.add(true);
    await tester.pump();
    h.visibility.add(true);
    await tester.pump();
    expect(h.signals, [SyncSignal.networkAvailable, SyncSignal.appReturnedToForeground]);
    await h.dispose();
  });
}
