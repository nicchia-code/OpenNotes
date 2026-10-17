import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/ui/settings/supabase_settings_dialog.dart';

void main() {
  test('A sign-in run that succeeded announces the success', () {
    expect(signInSyncOutcomeMessage(null, null), 'Sincronizzazione completata con successo.');
  });

  test('A sign-in run that failed shows its category, without a retry time when none waits', () {
    expect(
      signInSyncOutcomeMessage(SyncErrorCategory.network, null),
      'Sincronizzazione non riuscita: Rete non raggiungibile.',
    );
  });

  test('A failed sign-in run shows its category and the seconds until the retry', () {
    final now = DateTime(2026, 10, 17, 12);
    final dueAt = now.add(const Duration(seconds: 5));
    expect(
      signInSyncOutcomeMessage(SyncErrorCategory.timeout, dueAt, now: now),
      'Sincronizzazione non riuscita: Il cloud non risponde. Nuovo tentativo tra 5 s',
    );
  });
}
