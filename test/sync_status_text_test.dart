import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/sync_triggers.dart';
import 'package:open_notes/ui/sync/sync_status_label.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('syncStatusText', () {
    test('names each run state', () {
      expect(syncStatusText(SyncRunState.idle), 'Sincronizzato');
      expect(
        syncStatusText(SyncRunState.idle, setAside: true),
        'Alcune modifiche non si sincronizzano',
      );
      expect(syncStatusText(SyncRunState.running), 'Sincronizzazione in corso…');
      expect(
        syncStatusText(SyncRunState.offline),
        'Offline: le modifiche verranno inviate al ritorno della rete',
      );
    });

    test('waiting to retry names the error category and the countdown', () {
      expect(
        syncStatusText(
          SyncRunState.waitingToRetry,
          failure: SyncErrorCategory.network,
          retryInSeconds: 5,
        ),
        'Sincronizzazione non riuscita: Rete non raggiungibile. Nuovo tentativo tra 5 s',
      );
    });

    test('maps every error category to its Italian name', () {
      expect(syncErrorCategoryLabel(SyncErrorCategory.timeout), 'Il cloud non risponde');
      expect(syncErrorCategoryLabel(SyncErrorCategory.cloudUnavailable), 'Il cloud non risponde');
      expect(syncErrorCategoryLabel(SyncErrorCategory.sessionExpired), 'Accesso scaduto: accedi di nuovo');
      expect(syncErrorCategoryLabel(SyncErrorCategory.unexpected), 'Errore imprevisto');
    });
  });

  group('syncRetryCountdown', () {
    final now = DateTime(2026, 3, 10, 15, 0, 0);

    test('counts whole seconds left, rounding up, never negative', () {
      expect(syncRetryCountdown(now.add(const Duration(seconds: 15)), now: now), 15);
      expect(syncRetryCountdown(now.add(const Duration(milliseconds: 1500)), now: now), 2);
      expect(syncRetryCountdown(now.subtract(const Duration(seconds: 3)), now: now), 0);
    });
  });

  group('syncErrorCategoryOf', () {
    test('classifies network and timeout failures', () {
      expect(syncErrorCategoryOf(const SocketException('no route')), SyncErrorCategory.network);
      expect(syncErrorCategoryOf(TimeoutException('slow')), SyncErrorCategory.timeout);
    });

    test('classifies a status error from the cloud', () {
      expect(syncErrorCategoryOf(const StorageException('down', statusCode: '503')), SyncErrorCategory.cloudUnavailable);
      expect(syncErrorCategoryOf(const StorageException('denied', statusCode: '401')), SyncErrorCategory.sessionExpired);
    });

    test('classifies an unknown error as unexpected', () {
      expect(syncErrorCategoryOf(StateError('bad')), SyncErrorCategory.unexpected);
    });
  });

  group('SyncTriggers.isOffline', () {
    test('is false until connectivity is reported, then follows it', () async {
      final connectivity = StreamController<List<ConnectivityResult>>();
      final triggers = SyncTriggers(
        connectivityChanges: connectivity.stream,
        checkConnectivity: () async => [ConnectivityResult.wifi],
        visibilityChanges: const Stream<bool>.empty(),
        initiallyVisible: true,
      );
      expect(triggers.isOffline, isFalse);

      connectivity.add([ConnectivityResult.none]);
      await Future<void>.delayed(Duration.zero);
      expect(triggers.isOffline, isTrue);

      connectivity.add([ConnectivityResult.wifi]);
      await Future<void>.delayed(Duration.zero);
      expect(triggers.isOffline, isFalse);

      triggers.dispose();
      await connectivity.close();
    });
  });
}
