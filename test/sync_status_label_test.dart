import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_notes/ui/sync/sync_status_label.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('it_IT', null);
  });

  final now = DateTime(2026, 3, 10, 15, 0, 0);

  group('syncRelativeTime', () {
    test('is "adesso" under a minute, also for a moment slightly in the future', () {
      expect(syncRelativeTime(now, now: now), 'adesso');
      expect(syncRelativeTime(now.subtract(const Duration(seconds: 59)), now: now), 'adesso');
      expect(syncRelativeTime(now.add(const Duration(seconds: 30)), now: now), 'adesso');
    });

    test('counts minutes under the hour', () {
      expect(syncRelativeTime(now.subtract(const Duration(minutes: 1)), now: now), '1 minuto fa');
      expect(syncRelativeTime(now.subtract(const Duration(minutes: 2)), now: now), '2 minuti fa');
      expect(syncRelativeTime(now.subtract(const Duration(minutes: 59, seconds: 59)), now: now), '59 minuti fa');
    });

    test('uses the clock time of today from one hour on', () {
      expect(syncRelativeTime(DateTime(2026, 3, 10, 14, 0), now: now), 'oggi alle 14:00');
      expect(syncRelativeTime(DateTime(2026, 3, 10, 0, 5), now: now), 'oggi alle 00:05');
    });

    test('uses "ieri" for the previous calendar day from one hour on', () {
      expect(syncRelativeTime(DateTime(2026, 3, 9, 14, 32), now: now), 'ieri alle 14:32');
      expect(syncRelativeTime(DateTime(2026, 3, 9, 23, 50), now: DateTime(2026, 3, 10, 1, 30)), 'ieri alle 23:50');
    });

    test('uses day and month for older days, in Italian with 24 hour time', () {
      expect(syncRelativeTime(DateTime(2026, 3, 3, 14, 32), now: now), '3 marzo alle 14:32');
      expect(syncRelativeTime(DateTime(2026, 3, 3, 21, 7), now: now), '3 marzo alle 21:07');
    });
  });

  group('syncLastSyncedLabel', () {
    test('says "Mai sincronizzato" when no sync has completed', () {
      expect(syncLastSyncedLabel(null, now: now), 'Mai sincronizzato');
    });

    test('prefixes the relative time of the last completed sync', () {
      expect(syncLastSyncedLabel(now, now: now), 'Ultima sincronizzazione: adesso');
      expect(
        syncLastSyncedLabel(DateTime(2026, 3, 3, 14, 32), now: now),
        'Ultima sincronizzazione: 3 marzo alle 14:32',
      );
    });
  });
}
