import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
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

    test('classifies a database answer by its HTTP status', () {
      SyncErrorCategory categoryOf(String code) =>
          syncErrorCategoryOf(PostgrestException(message: 'answer', code: code));
      expect(categoryOf('500'), SyncErrorCategory.cloudUnavailable);
      expect(categoryOf('503'), SyncErrorCategory.cloudUnavailable);
      expect(categoryOf('408'), SyncErrorCategory.cloudUnavailable);
      expect(categoryOf('429'), SyncErrorCategory.cloudUnavailable);
      expect(categoryOf('401'), SyncErrorCategory.sessionExpired);
      expect(categoryOf('400'), SyncErrorCategory.unexpected);
      expect(categoryOf('404'), SyncErrorCategory.unexpected);
    });

    test('leaves a database error code that is not an HTTP status unexpected', () {
      expect(syncErrorCategoryOf(const PostgrestException(message: 'denied', code: '42501')), SyncErrorCategory.unexpected);
      expect(syncErrorCategoryOf(const PostgrestException(message: 'stale', code: 'PGRST301')), SyncErrorCategory.unexpected);
    });

    test('a connection cut during an answer is a network failure', () {
      expect(
        syncErrorCategoryOf(http.ClientException('Connection closed while receiving data')),
        SyncErrorCategory.network,
      );
    });

    test('classifies an unknown error as unexpected', () {
      expect(syncErrorCategoryOf(StateError('bad')), SyncErrorCategory.unexpected);
    });
  });

  group('isCloudRejection', () {
    bool refused(String code) => isCloudRejection(PostgrestException(message: 'answer', code: code));

    test('counts a 4xx answer other than 401, 408 and 429', () {
      expect(refused('400'), isTrue);
      expect(refused('403'), isTrue);
      expect(refused('409'), isTrue);
      expect(refused('401'), isFalse);
      expect(refused('408'), isFalse);
      expect(refused('429'), isFalse);
      expect(refused('503'), isFalse);
    });

    test('counts constraint, invalid data and permission database errors', () {
      expect(refused('23505'), isTrue);
      expect(refused('23503'), isTrue);
      expect(refused('22P02'), isTrue);
      expect(refused('42501'), isTrue);
    });

    test('does not count transient database errors, connection or cloud failures', () {
      expect(refused('40001'), isFalse);
      expect(refused('40P01'), isFalse);
      expect(refused('55P03'), isFalse);
      expect(refused('54000'), isFalse);
      expect(refused('08006'), isFalse);
      expect(refused('53300'), isFalse);
      expect(refused('57014'), isFalse);
      expect(refused('58030'), isFalse);
      expect(refused('XX000'), isFalse);
      expect(refused('PGRST301'), isFalse);
    });

    test('an error without a code is not a refusal', () {
      expect(isCloudRejection(const PostgrestException(message: 'no code')), isFalse);
      expect(isCloudRejection(StateError('bad')), isFalse);
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
