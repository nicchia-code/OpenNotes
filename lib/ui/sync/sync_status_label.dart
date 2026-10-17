import 'package:intl/intl.dart';

import '../../core/services/sync_service.dart';

/// Relative time of a sync moment in Italian, as the UI Requirement of the sync status names it:
/// "adesso", "N minuti fa" under the hour, then "oggi alle HH:mm", "ieri alle HH:mm" and "d MMMM alle HH:mm".
String syncRelativeTime(DateTime when, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final elapsed = current.difference(when);
  if (elapsed < const Duration(minutes: 1)) return 'adesso';
  if (elapsed < const Duration(hours: 1)) {
    final minutes = elapsed.inMinutes;
    return minutes == 1 ? '1 minuto fa' : '$minutes minuti fa';
  }

  final time = DateFormat('HH:mm', 'it_IT').format(when);
  // Calendar days, counted on UTC dates so that daylight saving changes do not shift the count.
  final daysAgo = DateTime.utc(current.year, current.month, current.day)
      .difference(DateTime.utc(when.year, when.month, when.day))
      .inDays;
  if (daysAgo == 0) return 'oggi alle $time';
  if (daysAgo == 1) return 'ieri alle $time';
  return '${DateFormat('d MMMM', 'it_IT').format(when)} alle $time';
}

/// Second line of the sync status tooltip: "Ultima sincronizzazione: <relative time>", or "Mai sincronizzato"
/// when the device has never completed a sync.
String syncLastSyncedLabel(DateTime? lastSyncedAt, {DateTime? now}) => lastSyncedAt == null
    ? 'Mai sincronizzato'
    : 'Ultima sincronizzazione: ${syncRelativeTime(lastSyncedAt, now: now)}';

/// Name of a failed run's error category, as the sync status shows it.
String syncErrorCategoryLabel(SyncErrorCategory category) => switch (category) {
      SyncErrorCategory.network => 'Rete non raggiungibile',
      SyncErrorCategory.timeout || SyncErrorCategory.cloudUnavailable => 'Il cloud non risponde',
      SyncErrorCategory.sessionExpired => 'Accesso scaduto: accedi di nuovo',
      SyncErrorCategory.unexpected => 'Errore imprevisto',
    };

/// First line of the sync status tooltip for [state]; [failure] and [retryInSeconds] apply to a run waiting to retry,
/// [setAside] to an idle run while changes are set aside.
String syncStatusText(
  SyncRunState state, {
  SyncErrorCategory? failure,
  int retryInSeconds = 0,
  bool setAside = false,
}) => switch (state) {
      SyncRunState.idle => setAside ? 'Alcune modifiche non si sincronizzano' : 'Sincronizzato',
      SyncRunState.running => 'Sincronizzazione in corso…',
      SyncRunState.waitingToRetry =>
        'Sincronizzazione non riuscita: ${syncErrorCategoryLabel(failure ?? SyncErrorCategory.unexpected)}. '
            'Nuovo tentativo tra $retryInSeconds s',
      SyncRunState.offline => 'Offline: le modifiche verranno inviate al ritorno della rete',
    };

/// Whole seconds left until [dueAt], never negative.
int syncRetryCountdown(DateTime dueAt, {DateTime? now}) {
  final left = dueAt.difference(now ?? DateTime.now());
  if (left <= Duration.zero) return 0;
  return (left.inMilliseconds + 999) ~/ 1000;
}
