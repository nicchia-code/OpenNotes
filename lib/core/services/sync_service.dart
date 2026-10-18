import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';
import 'database_service.dart';
import 'vault_service.dart';
import 'sync_triggers.dart';
import 'sync_log.dart';

/// A change the cloud sync made to the local copy, emitted on [SyncService.remoteChanges].
sealed class RemoteChange {
  const RemoteChange();
}

/// CLOUD_NOTE_APPLIED: a cloud note created or replaced the local copy.
final class CloudNoteApplied extends RemoteChange {
  final String noteId;
  /// Whether the cloud version that replaced the local copy is protected.
  final bool isLocked;
  const CloudNoteApplied(this.noteId, {required this.isLocked});
}

/// CLOUD_NOTE_REMOVED: a note removed from this device because the cloud deleted it: a realtime delete, a sync run that
/// found it gone, or a queued save that the cloud answered with a delete.
final class CloudNoteRemoved extends RemoteChange {
  final String noteId;
  const CloudNoteRemoved(this.noteId);
}

/// SAMPLE_NOTE_DISCARDED: a never-synced welcome note removed for good because the cloud already has notes.
final class SampleNoteDiscarded extends RemoteChange {
  final String noteId;
  const SampleNoteDiscarded(this.noteId);
}

/// PREVIOUS_ACCOUNT_NOTE_REMOVED: a synced note removed for good when another account connected to this device.
final class PreviousAccountNoteRemoved extends RemoteChange {
  final String noteId;
  const PreviousAccountNoteRemoved(this.noteId);
}

/// CLOUD_FOLDER_REMOVED: a local folder removed because the cloud deleted it.
final class CloudFolderRemoved extends RemoteChange {
  final String folderId;
  const CloudFolderRemoved(this.folderId);
}

/// Follows the status of the Realtime channel (realtime-channel Listening and Interrupted). A SUBSCRIBED that follows an
/// interruption is a reconnection; the first SUBSCRIBED of a channel is not.
class RealtimeConnection {
  bool _interrupted = false;

  /// Takes the next status of the channel; returns whether it is a reconnection (REALTIME_CONNECTED).
  bool onStatus(RealtimeSubscribeStatus status) {
    if (status != RealtimeSubscribeStatus.subscribed) {
      _interrupted = true;
      return false;
    }
    final reconnected = _interrupted;
    _interrupted = false;
    return reconnected;
  }
}

/// Applies realtime changes one at a time, in arrival order. A change that fails goes to [_onError] and the changes
/// after it are still applied. [clear] discards the changes not yet applied (Model: a closed channel applies nothing).
class RealtimeChangeQueue {
  RealtimeChangeQueue(this._onError);

  final void Function(Object error) _onError;
  Future<void> _tail = Future<void>.value();
  int _generation = 0;

  /// Discards the changes queued so far that have not started yet.
  void clear() => _generation++;

  /// Queues [apply] behind the changes added before it; the returned future completes once it has run.
  Future<void> add(Future<void> Function() apply) {
    final generation = _generation;
    return _tail = _tail.then((_) async {
      if (generation != _generation) return;
      try {
        await apply();
      } catch (error) {
        _onError(error);
      }
    });
  }
}

/// State of the sync run as the sync status shows it (Model: sync-run).
enum SyncRunState { idle, running, waitingToRetry, offline }

/// Category of a failed sync run, as the user sees it (Requirements: rules#sync-run).
enum SyncErrorCategory { network, timeout, cloudUnavailable, sessionExpired, unexpected }

/// A queued change the sync has set aside, as the settings window lists it. [cloudHasCopy] is true only when the cloud
/// holds a copy that is not deleted: "Usa la versione del cloud" is offered only then.
class SetAsideChange {
  final String entityType;
  final String entityId;
  final String title;
  final bool cloudHasCopy;

  const SetAsideChange({
    required this.entityType,
    required this.entityId,
    required this.title,
    required this.cloudHasCopy,
  });
}

/// What one sync run has read and sent so far. Each run has its own.
class _SyncRun {
  _SyncRun(this.client, this.userId, this.deadline);

  final SupabaseClient client;
  final String userId;
  /// When the run ends: each cloud request gets at most the time left until then.
  final DateTime deadline;
  /// Whether the run reads every row (a full check) rather than only the rows changed since the last revision.
  bool readAll = false;
  /// Notes and folders whose cloud version the user chose; applied even when their revision is already known.
  final Set<String> chosenNotes = {};
  final Set<String> chosenFolders = {};
  /// Cloud copies read or learned by this run, by id, the highest revision of each; placeholders included.
  final Map<String, Map<String, dynamic>> cloudNotes = {};
  final Map<String, Map<String, dynamic>> cloudFolders = {};
  /// Cloud copies that replace the local copy whatever their revision: chosen, or won a conflict, or conflict with an
  /// unsynced local copy.
  final Set<String> forcedNotes = {};
  final Set<String> forcedFolders = {};
  /// Ids of every row of a full read; empty on an incremental run.
  final Set<String> fullNoteIds = {};
  final Set<String> fullFolderIds = {};
  /// Rows this run has written, which the cloud has now.
  final Set<String> pushedNotes = {};
  final Set<String> pushedFolders = {};
  /// Notes whose queued change the cloud refused in this run: the unsynced sweep leaves them.
  final Set<String> refusedNotes = {};
  /// Attachment paths the cloud has, as this device knows them.
  final Set<String> cloudAttachments = {};
  /// Whether the cloud has a note of the user not deleted for good; read once, when a welcome note needs it.
  bool? cloudHasNotes;
  /// The highest revision read by this run.
  int? highestRevision;

  /// Whether the session this run started with is still there. Without it no request goes to the cloud, since the
  /// request would be sent as an anonymous user.
  bool get hasSession {
    final session = client.auth.currentSession;
    return session != null && session.user.id == userId;
  }

  /// Throws a timeout once the run's time is up: the local steps are bounded by the run as well (Requirements: tempi massimi).
  void checkDeadline() {
    if (!DateTime.now().isBefore(deadline)) throw TimeoutException('sync run');
  }

  void keepNote(Map<String, dynamic> row, {bool forced = false}) {
    final id = row['id'] as String;
    _keep(cloudNotes, id, row);
    if (forced) forcedNotes.add(id);
  }

  void keepFolder(Map<String, dynamic> row, {bool forced = false}) {
    final id = row['id'] as String;
    _keep(cloudFolders, id, row);
    if (forced) forcedFolders.add(id);
  }

  void _keep(Map<String, Map<String, dynamic>> copies, String id, Map<String, dynamic> row) {
    final known = copies[id];
    final revision = row['revision'] as int?;
    if (known == null || (revision ?? 0) >= ((known['revision'] as int?) ?? 0)) copies[id] = row;
    final highest = highestRevision;
    if (revision != null && (highest == null || revision > highest)) highestRevision = revision;
  }
}

/// Thrown when the session ends during a sync run: the run stops before its next cloud step, schedules no retry and
/// leaves the queue as it is.
final class _SignedOutDuringRun implements Exception {
  const _SignedOutDuringRun();
}

/// How the cloud answered one write of a queued change or of a note.
sealed class _PushOutcome {
  const _PushOutcome();
}

/// The cloud wrote the row, on [revision].
final class _Accepted extends _PushOutcome {
  const _Accepted(this.revision);
  final int? revision;
}

/// The cloud copy is newer than the local change, which is discarded; [row] is that copy.
final class _CloudWon extends _PushOutcome {
  const _CloudWon(this.row);
  final Map<String, dynamic> row;
}

/// The change lost to the cloud on every attempt; it stays queued for the next run.
final class _Unsettled extends _PushOutcome {
  const _Unsettled();
}

/// The cloud no longer has the row the device had seen: it was removed there.
final class _Gone extends _PushOutcome {
  const _Gone();
}

/// Category of the error that failed a sync run.
SyncErrorCategory syncErrorCategoryOf(Object error) {
  if (error is TimeoutException) return SyncErrorCategory.timeout;
  // A connection cut during an answer surfaces as the HTTP client's ClientException, not as a socket error.
  if (error is SocketException ||
      error is HandshakeException ||
      error is HttpException ||
      error is http.ClientException) {
    return SyncErrorCategory.network;
  }
  if (error is AuthRetryableFetchException) return SyncErrorCategory.network;
  if (error is AuthException) return SyncErrorCategory.sessionExpired;
  if (error is StorageException) return _categoryOfCloudStatus(error.statusCode) ?? SyncErrorCategory.unexpected;
  // Database answers carry their HTTP status as the code when the body has no error code (see isCloudRejection).
  if (error is PostgrestException) return _categoryOfCloudStatus(error.code) ?? SyncErrorCategory.unexpected;
  return SyncErrorCategory.unexpected;
}

/// Category of a cloud answer from its HTTP status [code], or null when the status does not sort it: 401 is an expired
/// session; 5xx, 408 and 429 are a cloud that does not answer. Any other value (including a database error code) is null.
SyncErrorCategory? _categoryOfCloudStatus(String? code) {
  if (code == null || !RegExp(r'^\d{3}$').hasMatch(code)) return null;
  final status = int.parse(code);
  if (status == 401) return SyncErrorCategory.sessionExpired;
  if (status >= 500 || status == 408 || status == 429) return SyncErrorCategory.cloudUnavailable;
  return null;
}

/// Whether the cloud refused a queued change: a 4xx answer other than 401, 408 and 429, or a database error for a
/// constraint (class 23), invalid data (class 22) or permission (class 42). Any other error, such as a transient
/// database error (40, 55, 54), is not a refusal: the change stays queued without being counted and the run fails.
bool isCloudRejection(Object error) {
  if (error is! PostgrestException) return false;
  final code = error.code;
  if (code == null) return false;
  // A response without a database error code carries its HTTP status as three digits: 401 is a session problem and
  // 408, 429 and 5xx are retried later.
  if (RegExp(r'^\d{3}$').hasMatch(code)) {
    final status = int.parse(code);
    return status >= 400 && status < 500 && status != 401 && status != 408 && status != 429;
  }
  // Database error code (SQLSTATE): only constraint, invalid data and permission errors are refusals.
  return RegExp(r'^(22|23|42)').hasMatch(code);
}

/// Bidirectional Local-First Sync Service for Supabase.
/// Operates seamlessly offline and syncs with Supabase when online.
class SyncService extends ChangeNotifier {
  final DatabaseService _dbService;
  final VaultService _vaultService;

  bool _isConfigured = false;
  bool _isSyncing = false;
  String? _supabaseUrl;
  String? _supabaseAnonKey;
  DateTime? _lastSyncedAt;
  RealtimeChannel? _realtimeChannel;
  RealtimeChangeQueue? _realtimeChanges;
  StreamSubscription<AuthState>? _authSubscription;
  /// True only while the app waits for the browser to return from Google sign-in (Model: Awaiting login).
  bool _awaitingLogin = false;
  String? _signInError;
  bool _supabasePrepared = false;
  final StreamController<RemoteChange> _remoteChanges = StreamController<RemoteChange>.broadcast();
  final SyncTriggers? _triggers;
  StreamSubscription<SyncSignal>? _triggerSub;
  SyncErrorCategory? _lastFailure;
  /// The app log where failures are written, read by the user; null leaves them to the debug console only.
  final SyncLog? _log;
  /// Failed runs in a row; the wait before the next retry grows with them (see [syncRetryWait]).
  int _failedRunsInSeries = 0;
  int _pendingChangeCount = 0;
  int _setAsideCount = 0;
  /// Notes whose cloud copy the user chose over the local one (CLOUD_VERSION_REQUESTED): the next run applies that copy
  /// even when its revision is already known here.
  final Set<String> _noteVersionRequests = {};
  /// Folders whose cloud version the user chose over the local one (CLOUD_VERSION_REQUESTED).
  final Set<String> _folderVersionRequests = {};
  /// Requests that arrived during a run: one more run starts when it ends, a full check when [_rerunFull].
  bool _rerunWanted = false;
  bool _rerunFull = false;
  /// The retry after a failed run is a full check when the failed run was one, or a request remembered during it asked.
  bool _retryFull = false;
  /// Set while Offline: the return of the network starts a full check.
  bool _fullOnNetwork = false;
  /// The run in progress, so that a request remembered during it can wait for its end.
  Future<void>? _activeRun;
  /// The first run started by the last sign-in return; completes when that run has ended. A run it starts afterwards is not waited for.
  Future<void>? _signInRun;
  /// The sign-in whose first run has not started yet; the next run to start completes it when that run has ended.
  Completer<void>? _signInRunEnded;
  /// Timeouts of a request to the cloud and of a whole run (Requirements: tempi massimi).
  final Duration requestTimeout;
  final Duration runTimeout;
  /// Writes of a conflicting change are tried this many times before it stays queued for the next run.
  static const int _maxPushAttempts = 5;

  SyncService(
    this._dbService,
    this._vaultService, {
    SyncTriggers? triggers,
    SyncLog? log,
    this.requestTimeout = const Duration(seconds: 15),
    this.runTimeout = const Duration(minutes: 2),
  }) : _triggers = triggers, _log = log {
    _triggerSub = triggers?.signals.listen((signal) {
      // The status shows the connection and the retry wait, which the triggers hold.
      notifyListeners();
      switch (signal) {
        case SyncSignal.appReturnedToForeground:
          _start(full: false);
        case SyncSignal.networkAvailable:
          // Model: the return of the network runs at once; a full check only when one was remembered for it.
          final full = _fullOnNetwork;
          _fullOnNetwork = false;
          _start(full: full);
        case SyncSignal.networkLost:
          // Model: NETWORK_LOST cancels the scheduled retry; the full check that retry owed is remembered for the return
          // of the network. A run in progress keeps it: its own outcome decides (see _runOnce).
          if (_retryFull && !_isSyncing) {
            _fullOnNetwork = true;
            _retryFull = false;
          }
        case SyncSignal.syncIntervalElapsed:
          _start(full: false, startsWhileWaiting: false);
        case SyncSignal.syncRetryDue:
          _start(full: _retryFull);
      }
    });
  }

  bool get isConfigured => _isConfigured;
  bool get isSyncing => _isSyncing;
  String? get supabaseUrl => _supabaseUrl;
  String? get supabaseAnonKey => _supabaseAnonKey;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  /// Category of the last failed run; null after a completed run.
  SyncErrorCategory? get lastFailure => _lastFailure;
  /// Changes waiting in the queue, shown as "Modifiche in attesa" in the settings window.
  int get pendingChangeCount => _pendingChangeCount;
  /// Changes the sync has set aside, which the sync status flags as "Alcune modifiche non si sincronizzano".
  int get setAsideCount => _setAsideCount;
  /// What the sync run is doing, as the sync status shows it.
  SyncRunState get runState {
    if (_isSyncing) return SyncRunState.running;
    if (_triggers?.isOffline ?? false) return SyncRunState.offline;
    if (_triggers?.retryDueAt != null) return SyncRunState.waitingToRetry;
    return SyncRunState.idle;
  }
  /// When the scheduled retry is due; null when no retry waits.
  DateTime? get retryDueAt => _triggers?.retryDueAt;
  bool get isAwaitingLogin => _awaitingLogin;
  /// Ends when the first sync run started by the last sign-in has ended, even if it already ended before this was awaited.
  /// Only meaningful when [signInRunStarted]: a sign-in while offline starts no run.
  Future<void> get signInRun => _signInRun ?? Future<void>.value();
  /// Whether the last sign-in started a sync run; false when the sign-in happened while offline.
  bool get signInRunStarted => _signInRun != null;
  void setAwaitingLogin(bool value) {
    _awaitingLogin = value;
    if (value) _signInError = null;
    // The settings window waits for this change: a failed return must wake it, not leave it on "Apertura browser".
    notifyListeners();
  }

  /// Message of the last sign-in return that carried an error (e.g. the user cancelled), received through the app link.
  String? get signInError => _signInError;

  /// Emits when a cloud change has been applied to or removed from the local copy: a note stored
  /// ([CloudNoteApplied]), a note or folder removed ([CloudNoteRemoved], [CloudFolderRemoved]) or a note discarded
  /// by a sync run ([SampleNoteDiscarded], [PreviousAccountNoteRemoved]). Listeners reload their lists on each
  /// event, even while a full sync is running.
  Stream<RemoteChange> get remoteChanges => _remoteChanges.stream;

  SupabaseClient? get _client {
    if (!_isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => _client?.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // Cloud address and key come only from the build variables: no value is embedded in the code.
  static const String _buildSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _buildSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const String _ownerKey = 'local_owner_id';

  /// Last cloud revision downloaded (int); absent until a full check with revisions has completed.
  static const String lastRevisionKey = 'sync_last_revision';
  /// When the last sync completed (ISO 8601 text).
  static const String lastCompletedAtKey = 'sync_last_completed_at';

  static const String _attachmentBucket = 'note-attachments';
  // A reference starts with `attachments/`; one inside an absolute path (`/x/attachments/a.png`) is not a vault reference.
  static final RegExp _attachmentRef = RegExp(r'(?<![\w./\\\-])attachments/[\w.\-]+');

  /// Build variables that are missing or blank; the cloud is prepared only when none is missing.
  List<String> get missingBuildVariables => [
        if (_buildSupabaseUrl.trim().isEmpty) 'SUPABASE_URL',
        if (_buildSupabaseAnonKey.trim().isEmpty) 'SUPABASE_ANON_KEY',
      ];

  /// Notice naming the missing build variables; null when the cloud can be prepared.
  String? get notConfiguredMessage {
    final missing = missingBuildVariables;
    if (missing.isEmpty) return null;
    if (missing.length == 2) return 'Cloud non configurato: mancano SUPABASE_URL e SUPABASE_ANON_KEY.';
    return 'Cloud non configurato: manca ${missing.single}.';
  }

  /// Prepares the cloud connection from the build variables only; the cloud configuration is not stored on the device,
  /// but the time of the last completed sync is restored from the local preferences.
  Future<void> init() async {
    // The last completed sync is kept across restarts: it is read before anything else, cloud configured or not.
    final prefs = await SharedPreferences.getInstance();
    _lastSyncedAt = DateTime.tryParse(prefs.getString(lastCompletedAtKey) ?? '');
    if (missingBuildVariables.isNotEmpty) return;
    await initializeSupabase(_buildSupabaseUrl.trim(), _buildSupabaseAnonKey.trim());
  }

  /// Dynamically initializes Supabase client.
  Future<bool> initializeSupabase(String url, String anonKey) async {
    try {
      try {
        await Supabase.initialize(url: url.trim(), anonKey: anonKey.trim());
        _supabasePrepared = true;
      } catch (e) {
        // Ignored only when the connection was already prepared in this run
        if (!_supabasePrepared) rethrow;
        debugPrint('Supabase already initialized or reinitializing: $e');
      }

      _supabaseUrl = url.trim();
      _supabaseAnonKey = anonKey.trim();
      _isConfigured = true;

      _setupAuthListener();

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
      notifyListeners();
      return false;
    }
  }

  /// Listens to Supabase Auth state changes to automatically connect Realtime and sync
  void _setupAuthListener() {
    _authSubscription?.cancel();
    final client = _client;
    if (client == null) return;

    _authSubscription = client.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;
      debugPrint('SyncService onAuthStateChange: $event (hasSession: ${session != null})');

      if (session != null && (event == AuthChangeEvent.initialSession || event == AuthChangeEvent.signedIn)) {
        // A session kept from an earlier launch starts the startup sync, like a fresh sign-in.
        _awaitingLogin = false;
        _signInError = null;
        // Model (Open): SIGNED_IN with a session closes the channel and opens a new one.
        _setupRealtimeSubscription();
        final initial = event == AuthChangeEvent.initialSession;
        // Model: an access, like the initial session, while offline starts no run: the full check it asks for is
        // remembered for the return of the network, and no sign-in run exists to announce.
        if (_triggers?.isOffline ?? false) {
          _fullOnNetwork = true;
          if (event == AuthChangeEvent.signedIn) _signInRun = null;
          notifyListeners();
          return;
        }
        Completer<void>? signInEnd;
        if (event == AuthChangeEvent.signedIn) {
          signInEnd = Completer<void>();
          _signInRun = signInEnd.future;
          _signInRunEnded = signInEnd;
        }
        await _start(full: true, startsWhileWaiting: !initial);
        // If no run took this sign-in (no account, or the run it joined ended before another one), it ends here.
        if (signInEnd != null && !signInEnd.isCompleted) {
          if (identical(_signInRunEnded, signInEnd)) _signInRunEnded = null;
          signInEnd.complete();
        }
      } else if (session != null && event == AuthChangeEvent.tokenRefreshed) {
        // A refreshed token starts a sync run (Model: TOKEN_REFRESHED); a channel that was closed is reopened.
        if (_realtimeChannel == null) _setupRealtimeSubscription();
        await _start(full: false);
      } else if (event == AuthChangeEvent.signedOut) {
        // Model: SIGNED_OUT closes the channel; local notes and folders stay. A later TOKEN_REFRESHED reopens it.
        // Changes received before sign-out but not yet applied are discarded, so they never reach the next account.
        _realtimeChanges?.clear();
        _realtimeChanges = null;
        _realtimeChannel?.unsubscribe();
        _realtimeChannel = null;
        // Model: SIGNED_OUT cancels the scheduled retry; no run starts from it and the changes stay queued.
        _triggers?.cancelRetry();
        _retryFull = false;
        _fullOnNetwork = false;
        notifyListeners();
      }
    }, onError: (Object error, StackTrace stackTrace) {
      // Only the return through the app link from the browser counts as a sign-in return (Model: Awaiting login).
      // Other errors on this channel, such as a failed token refresh while signed in, are not sign-in results.
      debugPrint('SyncService auth error: $error');
      if (!_awaitingLogin) return;
      _awaitingLogin = false;
      _signInError = error is AuthException ? error.message : error.toString();
      notifyListeners();
    });
  }

  /// Sets up the Realtime channel of notes and folders. Its status follows the connection: a SUBSCRIBED after an
  /// interruption asks a sync run to recover the changes made meanwhile. Changes are applied one at a time, in arrival order.
  void _setupRealtimeSubscription() {
    final client = _client;
    final user = currentUser;
    if (client == null || user == null) return;

    _realtimeChannel?.unsubscribe();
    _realtimeChanges?.clear();
    final channel = client.channel('public:notes_sync');
    _realtimeChannel = channel;
    final connection = RealtimeConnection();
    final changes = RealtimeChangeQueue((error) {
      // CHANGE_NOT_APPLIED: the failure is logged and a sync run recovers the change; the next change is still applied.
      _log?.record(category: 'realtimeChange', detail: error);
      _start(full: false, startsWhileWaiting: false);
    });
    _realtimeChanges = changes;

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            debugPrint('Realtime change received for notes: ${payload.eventType}');
            changes.add(() => handleRemoteNoteChange(payload));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'folders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            debugPrint('Realtime change received for folders: ${payload.eventType}');
            changes.add(() => handleRemoteFolderChange(payload));
          },
        )
        .subscribe((status, error) {
          // The status of a channel the app has already replaced or closed is not its concern.
          if (!identical(channel, _realtimeChannel)) return;
          debugPrint('Realtime channel status: $status${error == null ? '' : ' ($error)'}');
          // REALTIME_CONNECTED after an interruption: a sync run recovers the changes made elsewhere meanwhile.
          if (connection.onStatus(status)) _start(full: false);
        });
  }

  /// Applies a realtime note change to the local copy. A note deleted in the cloud reaches the device as a
  /// placeholder with `purged_at` set: a delete made elsewhere.
  Future<void> handleRemoteNoteChange(PostgresChangePayload payload) async {
    final eventType = payload.eventType;
    if (eventType == PostgresChangeEvent.delete) {
      final oldRecord = payload.oldRecord;
      final id = oldRecord['id'] as String?;
      if (id != null) await _removeRemoteNote(id, deletedAt: _recordTime(oldRecord));
      return;
    }

    final record = payload.newRecord;
    if (record.isEmpty) return;
    if (record['purged_at'] != null) {
      await _removeRemoteNote(record['id'] as String, deletedAt: _recordTime(record), revision: _recordRevision(record));
      return;
    }
    final applied = await applyRemoteNote(Note.fromSupabaseJson(record));
    // A note that replaces the local copy brings its missing attachments with it (Requirements: rules#realtime-channel).
    if (applied) await _downloadMissingAttachmentsOfRealtimeNote(record['id'] as String);
  }

  /// Downloads the missing attachments of a note just applied from the realtime channel. Uses its own run budget, and a
  /// failure is logged and retried by the next sync run.
  Future<void> _downloadMissingAttachmentsOfRealtimeNote(String noteId) async {
    final client = _client;
    final user = currentUser;
    final note = await _dbService.getNoteById(noteId);
    if (client == null || user == null || note == null) return;
    final run = _SyncRun(client, user.id, DateTime.now().add(runTimeout));
    await _downloadMissingAttachments(run, note.content);
  }

  /// REMOTE_NOTE_DELETED. Unless a queued change of the note made after the cloud delete still waits to be sent (that
  /// change then reaches the cloud and the note comes back), the note is removed and its queued changes are discarded at once.
  /// A trashed note is removed too: the cloud delete wins over the trash.
  Future<void> _removeRemoteNote(String id, {DateTime? deletedAt, int? revision}) async {
    final local = await _dbService.getNoteById(id);
    // A placeholder on a revision the device already has is an echo of its own send or an older delete: nothing happens.
    if (_alreadySeen(remoteRevision: revision, localRevision: local?.cloudRevision)) return;
    if (deletedAt != null && await _hasNewerQueuedNoteChange(id, deletedAt)) return;
    await _dbService.removeSyncActionsFor('note', id);
    await _dbService.deleteNoteRow(id);
    await _vaultService.deleteNoteFileIfUnused(_dbService, local?.filePath);
    if (local != null) _remoteChanges.add(CloudNoteRemoved(id));
  }

  /// Whether the cloud copy's revision is already known here: a revision not above the stored one. A copy whose revision
  /// the device does not know is new for it (Requirements: Download); a queued change of the copy still wins over it.
  static bool _alreadySeen({required int? remoteRevision, required int? localRevision}) =>
      localRevision != null && remoteRevision != null && remoteRevision <= localRevision;

  /// Stores a cloud note over the local copy when its revision is new for the device and no queued change of the note is
  /// strictly newer than the cloud copy.
  /// The download writes the vault file from the cloud title; when the title changed, the
  /// previous file stays in the vault as a copy that is no longer updated. Emits [remoteChanges] after each
  /// stored note, so the lists and an open editor update during a full sync too.
  /// Returns whether the cloud version was stored. [force] stores the cloud version even when its revision is already
  /// known here: the user chose it (CLOUD_VERSION_REQUESTED).
  Future<bool> applyRemoteNote(Note remoteNote, {bool force = false}) async {
    final localNote = await _dbService.getNoteById(remoteNote.id);
    // A cloud copy whose revision the device already has is not applied again. A queued change of the note made
    // strictly after the cloud copy wins: the local copy stays and is sent again.
    if (!force && localNote != null && _alreadySeen(
      remoteRevision: remoteNote.cloudRevision,
      localRevision: localNote.cloudRevision,
    )) {
      return false;
    }
    // A queued change of the note made strictly after the cloud copy wins: the local copy stays and is sent again.
    if (await _hasNewerQueuedNoteChange(remoteNote.id, remoteNote.updatedAt)) return false;
    // A cloud note can point at a folder this device no longer has (deleted here or elsewhere);
    // keep it in the default folder instead of letting it vanish from every folder view.
    final folderId = await _dbService.folderExists(remoteNote.folderId)
        ? remoteNote.folderId
        : Folder.defaultNotesId;
    final downloaded = remoteNote.copyWith(folderId: folderId);
    // A queued delete wins only over an older cloud copy: a cloud copy made at the same time or later replaces the note
    // and drops the queued delete. Otherwise the next sync run sends the delete.
    // ponytail: a delete queued during the file write below still lands; re-check after the write if that race matters.
    final deleteQueuedAt = await _dbService.pendingDeleteQueuedAt('note', remoteNote.id);
    if (deleteQueuedAt != null) {
      if (remoteNote.updatedAt.isBefore(deleteQueuedAt)) return false;
      await _dbService.removeSyncActionsFor('note', remoteNote.id, action: 'delete');
    }
    final saved = downloaded.copyWith(filePath: await _vaultService.saveNote(downloaded));
    // The cloud version wins over the older queued changes of the note: sending them would overwrite it.
    await _dbService.removeSyncActionsFor('note', remoteNote.id, action: 'upsert');
    await _dbService.upsertNote(saved);
    _remoteChanges.add(CloudNoteApplied(remoteNote.id, isLocked: saved.isLocked));
    return true;
  }

  /// Vault attachment paths (`attachments/<file>`) that a note's content refers to.
  static Set<String> attachmentRefs(String content) =>
      _attachmentRef.allMatches(content).map((m) => m.group(0)!).toSet();

  /// Removes from the bucket the attachments of a deleted note that no other cloud note uses.
  Future<void> _removeUnusedAttachments(
      SupabaseClient client, String userId, String deletedContent) async {
    final candidates = attachmentRefs(deletedContent);
    if (candidates.isEmpty) return;
    final remaining = await client.from('notes').select('content').eq('user_id', userId);
    for (final row in remaining as List) {
      candidates.removeAll(attachmentRefs(row['content'] as String));
    }
    if (candidates.isEmpty) return;
    await client.storage.from(_attachmentBucket).remove([
      for (final ref in candidates) '$userId/${ref.substring('attachments/'.length)}',
    ]);
  }

  Future<void> handleRemoteFolderChange(PostgresChangePayload payload) async {
    final eventType = payload.eventType;
    if (eventType == PostgresChangeEvent.delete) {
      final oldRecord = payload.oldRecord;
      final id = oldRecord['id'] as String?;
      if (id != null) await _removeRemoteFolder(id, deletedAt: _recordTime(oldRecord));
      return;
    }

    final record = payload.newRecord;
    if (record.isEmpty) return;
    // A folder deleted in the cloud reaches the device as a placeholder with `purged_at` set: a delete, not a folder.
    if (record['purged_at'] != null) {
      await _removeRemoteFolder(record['id'] as String, deletedAt: _recordTime(record), revision: _recordRevision(record));
      return;
    }
    // A queued delete of the folder yields to a cloud copy not older than it: _storeCloudFolder decides.
    if (await _storeCloudFolder(Folder.fromSupabaseJson(record))) {
      notifyListeners();
    }
  }

  /// REMOTE_FOLDER_DELETED. The last cloud version is the reference: a queued local change newer than it keeps the
  /// folder, and the next sync sends that change (it recreates the folder in the cloud). Without that version the delete applies.
  Future<void> _removeRemoteFolder(String id, {DateTime? deletedAt, int? revision}) async {
    final local = await _dbService.getFolderById(id);
    // A placeholder on a revision the device already has is an echo of its own send or an older delete: nothing happens.
    if (_alreadySeen(remoteRevision: revision, localRevision: local?.cloudRevision)) return;
    if (deletedAt != null && await _hasNewerQueuedFolderChange(id, deletedAt)) return;
    // A system folder is never deleted by the cloud: its local copy and its notes stay as they are.
    if (local?.isSystem ?? false) return;
    await _rewriteNotesMovedFrom(id);
    await _dbService.deleteFolder(id);
    // A change still queued for the deleted folder stays: the next sync sends it under "vince l'ultima modifica" (it is
    // sent only if it is strictly newer than the cloud version), so a newer rename recreates the folder in the cloud.
    notifyListeners();
    if (local != null) _remoteChanges.add(CloudFolderRemoved(id));
  }

  /// Rewrites the vault copies of the notes of a folder the cloud deleted, so they name Notes, where they move to.
  /// Runs before the folder is deleted: a failed write throws and the next run tries again.
  Future<void> _rewriteNotesMovedFrom(String folderId) async {
    final notes = await _dbService.getNotes(folderId: folderId, isDeleted: null);
    await _vaultService.rewriteMovedNotes(_dbService, [
      for (final note in notes) note.copyWith(folderId: Folder.defaultNotesId),
    ]);
  }

  /// Stores a cloud version of a folder unless a queued local change of it is strictly newer than that version: then
  /// the local folder stays. A queued delete of the folder is dropped unless the cloud version is older than it.
  /// Returns whether the local folder was stored.
  Future<bool> _storeCloudFolder(Folder remote, {bool force = false}) async {
    // An echo of this device's own send, or a version already stored, is not applied again.
    final local = await _dbService.getFolderById(remote.id);
    if (!force && local != null &&
        _alreadySeen(
          remoteRevision: remote.cloudRevision,
          localRevision: local.cloudRevision,
        )) {
      return false;
    }
    final deletedAt = await _dbService.getPendingSyncDeleteTime('folder', remote.id);
    if (deletedAt != null) {
      if (remote.updatedAt.isBefore(deletedAt)) return false;
      await _dbService.removePendingSyncDeletes('folder', remote.id);
    }
    if (await _hasNewerQueuedFolderChange(remote.id, remote.updatedAt)) return false;
    // The cloud version wins over the older queued renames of the folder: sending them would overwrite it.
    await _dbService.removeSyncActionsFor('folder', remote.id, action: 'upsert');
    await _dbService.upsertFolder(remote);
    return true;
  }

  /// Whether a queued upsert of the local folder [folderId] was made strictly after [cloudUpdatedAt].
  Future<bool> _hasNewerQueuedFolderChange(String folderId, DateTime cloudUpdatedAt) async {
    final local = await _dbService.getFolderById(folderId);
    if (local == null || !local.updatedAt.isAfter(cloudUpdatedAt)) return false;
    return _dbService.hasPendingSyncAction(entityType: 'folder', entityId: folderId, action: 'upsert');
  }

  /// Whether a queued change of the local note [noteId] was made strictly after [cloudUpdatedAt].
  Future<bool> _hasNewerQueuedNoteChange(String noteId, DateTime cloudUpdatedAt) async {
    final local = await _dbService.getNoteById(noteId);
    if (local == null || !local.updatedAt.isAfter(cloudUpdatedAt)) return false;
    return _dbService.hasPendingSyncAction(entityType: 'note', entityId: noteId, action: 'upsert');
  }

  /// The `updated_at` of a realtime record: the time of the change, or of the delete for a placeholder.
  static DateTime? _recordTime(Map<String, dynamic> record) => DateTime.tryParse(record['updated_at'] as String? ?? '');

  /// The `revision` of a realtime or read cloud row, when it has one.
  static int? _recordRevision(Map<String, dynamic> record) => (record['revision'] as num?)?.toInt();

  /// Local notes belong to the account that synced them. When another account syncs,
  /// the notes it already uploaded are removed here (they come back with the previous account);
  /// their unsent changes are discarded too, never sent to the new account (Model: pending-change, Discarded).
  /// Queued deletes of such notes removed for good before the switch are discarded too.
  /// Notes not yet uploaded are never dropped. Folders are not removed here: the pull removes the synced
  /// folders the cloud lacks, and keeps the ones with unsent changes.
  Future<void> _adoptAccount(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final owner = prefs.getString(_ownerKey);
    if (owner != null && owner != userId) {
      for (final note in await _dbService.getNotes(isDeleted: null)) {
        if (note.syncedAt == null) continue;
        await _dbService.removeSyncActionsFor('note', note.id);
        await _dbService.deleteNoteRow(note.id);
        await _vaultService.deleteNoteFileIfUnused(_dbService, note.filePath);
        _remoteChanges.add(PreviousAccountNoteRemoved(note.id));
      }
      for (final id in await _dbService.removeQueuedDeletesOfPurgedSyncedNotes()) {
        _remoteChanges.add(PreviousAccountNoteRemoved(id));
      }
      await _dbService.forgetCloudState();
      await prefs.remove(lastRevisionKey);
    }
    await prefs.setString(_ownerKey, userId);
  }

  /// Starts a sync run, or remembers the request for one run after the current one (Model: sync-run Running). A request
  /// needs a prepared cloud and a connected user, otherwise it is ignored. A start during the retry wait cancels the
  /// wait; while the system reports no connection only [startsOffline] starts a run. The returned future completes
  /// when the run, and the one it remembered, have ended.
  Future<void> _start({required bool full, bool startsWhileWaiting = true, bool startsOffline = false}) {
    if (_client == null || currentUser == null) return Future<void>.value();
    if (_isSyncing) {
      _rerunWanted = true;
      _rerunFull = _rerunFull || full;
      return _activeRun ?? Future<void>.value();
    }
    if ((_triggers?.isOffline ?? false) && !startsOffline) return Future<void>.value();
    if (_triggers?.retryDueAt != null) {
      if (!startsWhileWaiting) return Future<void>.value();
      // Model: the start cancels the wait and runs at once. That run retries the failed one, so it is full when the
      // failed run was; if it fails again, the waits start from 2 s.
      _triggers?.cancelRetry();
      _failedRunsInSeries = 0;
      full = full || _retryFull;
    }
    final run = _runLoop(full);
    _activeRun = run;
    return run;
  }

  /// Runs a sync, then one more run when requests arrived during it: a single run, full when one of them asked for it
  /// (Model: sync-run COMPLETED → Running).
  Future<void> _runLoop(bool full) async {
    // Model: a run that starts cancels the count of the previous one; the count restarts only when the run ends.
    _triggers?.cancelInterval();
    _isSyncing = true;
    notifyListeners();
    var nextFull = full;
    try {
      while (true) {
        // The run starting now is the first one started after a sign-in still waiting: it ends that sign-in run.
        final signInEnd = _signInRunEnded;
        _signInRunEnded = null;
        final completed = await _runOnce(nextFull).whenComplete(() => signInEnd?.complete());
        if (!completed || !_rerunWanted) break;
        nextFull = _rerunFull;
        _rerunWanted = false;
        _rerunFull = false;
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
      // A failed run keeps the retry it scheduled; the periodic interval waits for that retry, and none runs offline.
      if (_triggers?.retryDueAt == null && !(_triggers?.isOffline ?? false)) _triggers?.armInterval();
    }
  }

  /// One run, from the queue to the end of the pull. Returns whether it completed. A failure schedules the retry, or
  /// the wait for the network when the system reports none, and carries the full check and the requests remembered
  /// during the run into it (Model: sync-run FAILED).
  Future<bool> _runOnce(bool full) async {
    final client = _client;
    final user = currentUser;
    if (client == null || user == null) return false;
    final run = _SyncRun(client, user.id, DateTime.now().add(runTimeout));
    try {
      await _performRun(run, full: full);
      final completedAt = DateTime.now();
      await _saveRunResult(run, completedAt);
      _lastSyncedAt = completedAt;
      _lastFailure = null;
      _failedRunsInSeries = 0;
      _retryFull = false;
      await _refreshPendingChangeCount();
      return true;
    } on _SignedOutDuringRun {
      // The session ended during the run: no retry is scheduled, and the requests remembered during it are dropped
      // with the account. The queue stays as it is.
      debugPrint('Sync run stopped: signed out');
      _rerunWanted = false;
      _rerunFull = false;
      await _refreshPendingChangeCount();
      return false;
    } catch (error) {
      final category = syncErrorCategoryOf(error);
      _lastFailure = category;
      await _log?.record(category: category.name, detail: error);
      // Waits here so that requests arriving meanwhile are still remembered and join the retry below.
      await _refreshPendingChangeCount();
      final needsFull = full || _rerunFull;
      _rerunWanted = false;
      _rerunFull = false;
      if (_triggers?.isOffline ?? false) {
        // Model: FAILED → Offline. No attempt is scheduled; a full check is remembered for the return of the network.
        _fullOnNetwork = _fullOnNetwork || needsFull;
        _retryFull = false;
      } else {
        // Model: FAILED → Waiting to retry.
        _retryFull = _retryFull || needsFull;
        _triggers?.scheduleRetry(syncRetryWait(_failedRunsInSeries++));
      }
      return false;
    }
  }

  /// Stores what a completed run learned: the highest revision downloaded (never lower than before) and the time of the
  /// completed run. The cloud versions the user chose, and that this run read, are no longer requested.
  Future<void> _saveRunResult(_SyncRun run, DateTime completedAt) async {
    final prefs = await SharedPreferences.getInstance();
    var lastRevision = prefs.getInt(lastRevisionKey) ?? 0;
    final highest = run.highestRevision;
    if (highest != null && highest > lastRevision) lastRevision = highest;
    await prefs.setInt(lastRevisionKey, lastRevision);
    await prefs.setString(lastCompletedAtKey, completedAt.toIso8601String());
    _noteVersionRequests.removeWhere(run.chosenNotes.contains);
    _folderVersionRequests.removeWhere(run.chosenFolders.contains);
  }

  /// The fixed order of a run (Requirements: sync-run): account check, queue, reading the cloud, unsynced notes,
  /// folders, notes, attachments, and on a full check the removal of rows the cloud no longer has.
  Future<void> _performRun(_SyncRun run, {required bool full}) async {
    await _adoptAccount(run.userId);
    final prefs = await SharedPreferences.getInstance();
    final lastRevision = prefs.getInt(lastRevisionKey);
    // Every run is a full check until one has completed with revisions: the first run after an update, a new account.
    run.readAll = full || lastRevision == null;
    run.cloudAttachments.addAll(await _dbService.getCloudAttachmentPaths());
    run.chosenNotes.addAll(_noteVersionRequests);
    run.chosenFolders.addAll(_folderVersionRequests);

    await _pushQueue(run);
    await _readCloud(run, since: run.readAll ? null : lastRevision);
    if (run.readAll) await _adoptRevisions(run);
    await _sendUnsyncedNotes(run);
    await _applyCloudFolders(run);
    await _applyCloudNotes(run);
    await _downloadAttachmentsOfAllNotes(run);
    if (run.readAll) await _removeRowsMissingFromCloud(run);
  }

  /// Sends the queued changes that are not set aside, oldest first (Model: Pushing changes). A change the cloud refuses
  /// is counted on it, and the run goes on with the others.
  Future<void> _pushQueue(_SyncRun run) async {
    // The attachments of synced notes that failed before are retried here, inside the queue step (Requirements: sync-run).
    await _uploadAttachmentsOfSyncedNotes(run);
    // Set-aside changes stay queued but are not sent until the user decides (Model: pending-change, Set aside).
    // Changes queued while the queue is being sent (a save made by a listener, or a delete queued while a save was in
    // flight) go in the same run: each pass takes the items not sent yet, until a pass finds none.
    final handled = <String>{};
    var found = true;
    while (found) {
      found = false;
      final items = (await _dbService.getPendingSyncActions()).where((item) => (item['set_aside'] as int) == 0);
      for (final item in items.toList()) {
        // An item is sent once per entry: a replaced item has a new entry time, so it is sent again.
        if (!handled.add('${item['id']}:${item['created_at']}:${item['action']}')) continue;
        found = true;
        final entityType = item['entity_type'] as String;
        try {
          if (entityType == 'note') {
            await _sendQueuedNote(run, item);
          } else {
            await _sendQueuedFolder(run, item);
          }
        } on PostgrestException catch (error) {
          // Refused by the cloud: counted on this change, which is set aside after the third in a row. Network, timeout
          // and cloud failures are not refusals and fail the run.
          if (!isCloudRejection(error)) rethrow;
          debugPrint('Queued change refused: ${error.message}');
          if (entityType == 'note') run.refusedNotes.add(item['entity_id'] as String);
          await _dbService.recordRejectedSyncAction(item, error.message);
        }
      }
    }
  }

  /// Sends one queued note change: a save, or a delete that becomes a deletion placeholder on the cloud.
  Future<void> _sendQueuedNote(_SyncRun run, Map<String, dynamic> item) async {
    if (item['action'] == 'delete') {
      await _sendQueuedNoteDelete(run, item);
      return;
    }
    final id = item['entity_id'] as String;
    // A never-synced welcome note renamed after its save was queued: the save is not sent, the unsynced sweep decides.
    final queued = await _dbService.getNoteById(id);
    if (queued != null && queued.syncedAt == null && isWelcomeNote(queued)) {
      await _dbService.removeSyncActionIfUnchanged(item);
      return;
    }
    // A note this device synced before revisions were kept has no revision to send against. If the cloud no longer has
    // it, the note was deleted there, and its queued save is dropped with it, so the save cannot recreate it.
    if (queued != null && queued.syncedAt != null && queued.cloudRevision == null) {
      final cloudCopy = await _cloud(run, () => run.client.from('notes').select('id').eq('id', id).maybeSingle());
      if (cloudCopy == null) {
        await _dbService.removeSyncActionIfUnchanged(item);
        await _removeRemoteNote(id);
        return;
      }
    }
    final row = _notePushRow(jsonDecode(item['payload'] as String) as Map<String, dynamic>);
    await _uploadMissingAttachments(run, row['content'] as String);
    final outcome = await _pushRow(
      run,
      table: 'notes',
      row: row,
      baseRevision: item['base_revision'] as int?,
      localTime: DateTime.parse(row['updated_at'] as String),
    );
    switch (outcome) {
      case _Accepted(:final revision):
        await _dbService.removeSyncActionIfUnchanged(item);
        run.pushedNotes.add(id);
        final stored = await _dbService.getNoteById(id);
        if (stored != null) {
          await _dbService.upsertNote(
            stored.copyWith(syncedAt: stored.syncedAt ?? DateTime.now(), cloudRevision: revision),
          );
        }
        break;
      case _CloudWon(row: final cloud):
        // The cloud copy is newer than the save: the save is discarded (CHANGE_DISCARDED), and a deleted copy removes
        // the note here (CLOUD_NOTE_REMOVED) unless a newer save of it waits in the queue: that save stays and is sent
        // in this run; a live copy replaces the local one with the pull.
        await _dbService.removeSyncActionIfUnchanged(item);
        if (cloud['purged_at'] != null) {
          await _removeRemoteNote(id, deletedAt: _recordTime(cloud), revision: _recordRevision(cloud));
        } else {
          run.keepNote(cloud, forced: true);
        }
        break;
      case _Gone():
        // The cloud no longer has the note the device had seen: it was deleted there, so its save is dropped with it.
        await _dbService.removeSyncActionIfUnchanged(item);
        await _removeRemoteNote(id);
        break;
      case _Unsettled():
        break;
    }
  }

  /// A queued note delete becomes a deletion placeholder dated when the delete was queued. The attachments of the cloud
  /// copy that no other note uses are removed from the bucket.
  Future<void> _sendQueuedNoteDelete(_SyncRun run, Map<String, dynamic> item) async {
    final id = item['entity_id'] as String;
    final queuedAt = DateTime.parse(item['created_at'] as String);
    // Read before the placeholder is written: afterwards the cloud copy has no content left.
    final before = await _cloud(
      run,
      () => run.client.from('notes').select('content').eq('id', id).maybeSingle(),
    );
    final outcome = await _pushRow(
      run,
      table: 'notes',
      row: _notePlaceholder(id, queuedAt),
      baseRevision: item['base_revision'] as int?,
      localTime: queuedAt,
    );
    switch (outcome) {
      case _Accepted():
        run.pushedNotes.add(id);
        await _dbService.removeSyncActionIfUnchanged(item);
        if (before != null) await _removeUnusedAttachmentsSafely(run, before['content'] as String);
        break;
      case _CloudWon(row: final cloud):
        // The cloud copy is newer than the delete: the delete is discarded, and a live copy comes back with the pull.
        await _dbService.removeSyncActionIfUnchanged(item);
        if (cloud['purged_at'] == null) run.keepNote(cloud, forced: true);
        break;
      case _Gone():
        // The cloud has no copy to delete; the local note is already gone.
        await _dbService.removeSyncActionIfUnchanged(item);
        break;
      case _Unsettled():
        break;
    }
  }

  /// Sends one queued folder change: a save, or a delete that becomes a deletion placeholder carrying the name.
  Future<void> _sendQueuedFolder(_SyncRun run, Map<String, dynamic> item) async {
    final id = item['entity_id'] as String;
    final queuedAt = DateTime.parse(item['created_at'] as String);
    final baseRevision = item['base_revision'] as int?;
    var detachedFromParent = false;
    final _PushOutcome outcome;
    if (item['action'] == 'delete') {
      final at = queuedAt.toUtc().toIso8601String();
      // Read before the placeholder is written: the queue carries only the id, so the placeholder keeps the cloud copy's name.
      final before = await _cloud(
        run,
        () => run.client.from('folders').select('name').eq('id', id).maybeSingle(),
      );
      outcome = await _pushRow(
        run,
        table: 'folders',
        row: {'id': id, 'name': before?['name'] as String? ?? '', 'updated_at': at, 'purged_at': at},
        baseRevision: baseRevision,
        localTime: queuedAt,
      );
    } else {
      final payload = jsonDecode(item['payload'] as String) as Map<String, dynamic>;
      final row = await _folderPushRow(run, payload);
      detachedFromParent = payload['parent_id'] != null && row['parent_id'] == null;
      outcome = await _pushRow(
        run,
        table: 'folders',
        row: row,
        baseRevision: baseRevision,
        localTime: DateTime.parse(row['updated_at'] as String),
      );
    }
    switch (outcome) {
      case _Accepted(:final revision):
        await _dbService.removeSyncActionIfUnchanged(item);
        run.pushedFolders.add(id);
        final stored = await _dbService.getFolderById(id);
        if (stored != null) {
          // A subfolder the cloud took top-level is top-level here too: the local copy follows what was sent.
          await _dbService.upsertFolder(detachedFromParent
              ? Folder(
                  id: stored.id,
                  name: stored.name,
                  icon: stored.icon,
                  isSystem: stored.isSystem,
                  createdAt: stored.createdAt,
                  updatedAt: stored.updatedAt,
                  cloudRevision: revision,
                )
              : stored.copyWith(cloudRevision: revision));
        }
        break;
      case _CloudWon(row: final cloud):
        await _dbService.removeSyncActionIfUnchanged(item);
        if (cloud['purged_at'] == null) {
          run.keepFolder(cloud, forced: true);
        } else if (item['action'] != 'delete') {
          await _removeRemoteFolder(id, revision: _recordRevision(cloud));
        }
        break;
      case _Gone():
        // The cloud no longer has the folder: it leaves the device with every queued change of it, the newer ones too
        // (Model: CLOUD_FOLDER_REMOVED; Requirements: rules#sync-run).
        if (item['action'] != 'delete') await _removeRemoteFolder(id);
        await _dbService.removeSyncActionsFor('folder', id);
        break;
      case _Unsettled():
        break;
    }
  }

  /// The row of a queued folder save as the cloud takes it: UTC dates, the flag as a boolean, and no parent the cloud
  /// no longer has, so the subfolder goes top-level. The local folder is not changed.
  Future<Map<String, dynamic>> _folderPushRow(_SyncRun run, Map<String, dynamic> payload) async {
    final row = Map<String, dynamic>.from(payload)..remove('user_id');
    _toCloudUtc(row, ['created_at', 'updated_at']);
    if (row['is_system'] is int) row['is_system'] = row['is_system'] == 1;
    final parentId = row['parent_id'] as String?;
    if (parentId != null) {
      final parent = await _cloud(
        run,
        () => run.client.from('folders').select('id, purged_at').eq('id', parentId).maybeSingle(),
      );
      if (parent == null || parent['purged_at'] != null) row['parent_id'] = null;
    }
    return row;
  }

  /// The row of a queued note save as the cloud takes it: no local-only fields, tags as a list, flags as booleans, and
  /// UTC dates.
  static Map<String, dynamic> _notePushRow(Map<String, dynamic> payload) {
    final row = Map<String, dynamic>.from(payload)
      ..remove('user_id')
      ..remove('file_path')
      ..remove('synced_at');
    if (row['tags'] is String) {
      try {
        row['tags'] = jsonDecode(row['tags'] as String);
      } catch (_) {
        row['tags'] = <String>[];
      }
    } else if (row['tags'] == null) {
      row['tags'] = <String>[];
    }
    for (final flag in const ['is_pinned', 'is_locked', 'is_deleted']) {
      if (row[flag] is int) row[flag] = row[flag] == 1;
    }
    _toCloudUtc(row, ['deleted_at', 'created_at', 'updated_at']);
    return row;
  }

  /// The deletion placeholder of a note: no content, no tags, dated when the delete was queued.
  static Map<String, dynamic> _notePlaceholder(String id, DateTime deletedAt) {
    final at = deletedAt.toUtc().toIso8601String();
    return {'id': id, 'title': '', 'content': '', 'tags': <String>[], 'updated_at': at, 'purged_at': at};
  }

  /// Writes one row through the cloud's compare-and-set function on the revision it is based on (Requirements:
  /// rules#cloud-sync). A conflict is settled by "vince l'ultima modifica": the local change, made at [localTime], is
  /// sent again on the revision just read when it is strictly newer than the cloud row or the cloud has no row; otherwise
  /// the cloud row wins.
  Future<_PushOutcome> _pushRow(
    _SyncRun run, {
    required String table,
    required Map<String, dynamic> row,
    required int? baseRevision,
    required DateTime localTime,
  }) async {
    final isNote = table == 'notes';
    var base = baseRevision;
    for (var attempt = 0; attempt < _maxPushAttempts; attempt++) {
      final reply = await _cloud(
        run,
        () => run.client.rpc(
          isNote ? 'push_note' : 'push_folder',
          params: {isNote ? 'p_note' : 'p_folder': row, 'p_base_revision': base},
        ),
      );
      final answer = Map<String, dynamic>.from(reply as Map);
      if (answer['status'] == 'accepted') return _Accepted(answer['revision'] as int?);
      final cloud = answer['row'] == null ? null : Map<String, dynamic>.from(answer['row'] as Map);
      if (cloud == null) {
        // The device had seen a row the cloud no longer has: it was removed there.
        return const _Gone();
      }
      if (!localTime.isAfter(DateTime.parse(cloud['updated_at'] as String))) return _CloudWon(cloud);
      base = cloud['revision'] as int?;
    }
    return const _Unsettled();
  }

  /// Reads the rows to apply (Model: sync-run Reading cloud): those with a revision above [since], or all of them on a
  /// full check, and the rows of the notes and folders whose cloud version the user chose.
  Future<void> _readCloud(_SyncRun run, {required int? since}) async {
    final notes = await _readRows(run, 'notes', since: since);
    final folders = await _readRows(run, 'folders', since: since);
    if (run.readAll) {
      run.fullNoteIds.addAll(notes.map((row) => row['id'] as String));
      run.fullFolderIds.addAll(folders.map((row) => row['id'] as String));
    }
    for (final row in notes) {
      run.keepNote(row);
    }
    for (final row in folders) {
      run.keepFolder(row);
    }
    if (run.chosenNotes.isNotEmpty) {
      final chosen = await _cloud(
        run,
        () => run.client.from('notes').select().eq('user_id', run.userId).inFilter('id', run.chosenNotes.toList()),
      );
      for (final row in chosen as List) {
        run.keepNote(Map<String, dynamic>.from(row as Map), forced: true);
      }
    }
    if (run.chosenFolders.isNotEmpty) {
      final chosen = await _cloud(
        run,
        () => run.client.from('folders').select().eq('user_id', run.userId).inFilter('id', run.chosenFolders.toList()),
      );
      for (final row in chosen as List) {
        run.keepFolder(Map<String, dynamic>.from(row as Map), forced: true);
      }
    }
  }

  /// The rows of [table] of the user, page by page: those with a revision above [since], or all of them when null.
  Future<List<Map<String, dynamic>>> _readRows(_SyncRun run, String table, {required int? since}) {
    return readAllPages((from, to) async {
      final rows = await _cloud(run, () {
        final query = run.client.from(table).select().eq('user_id', run.userId);
        return since == null
            ? query.order('id').range(from, to)
            : query.gt('revision', since).order('revision').range(from, to);
      });
      return rows as List;
    });
  }

  /// The first full check with revisions (Requirements: Primo giro dopo l'aggiornamento). A local copy synced without a
  /// revision adopts the cloud revision when its fields match the cloud row. Otherwise the last change wins: a local copy
  /// strictly newer than the cloud row is queued again on that revision, and a cloud copy that wins is applied.
  Future<void> _adoptRevisions(_SyncRun run) async {
    for (final local in await _dbService.getNotes(isDeleted: null)) {
      final row = run.cloudNotes[local.id];
      if (row == null || local.cloudRevision != null || local.syncedAt == null) continue;
      final revision = row['revision'] as int?;
      if (_sameNoteFields(local, row)) {
        await _dbService.upsertNote(local.copyWith(cloudRevision: revision));
      } else if (local.updatedAt.isAfter(DateTime.parse(row['updated_at'] as String))) {
        await _dbService.upsertNote(local.copyWith(cloudRevision: revision));
        await _dbService.queueSyncAction(
          entityType: 'note',
          entityId: local.id,
          action: 'upsert',
          payload: jsonEncode(local.toSupabaseJson(run.userId)),
        );
        // Every queueing asks for a run at once; during this run the request is remembered for the next one.
        _start(full: false);
      } else {
        run.forcedNotes.add(local.id);
      }
    }
    for (final local in await _dbService.getFolders()) {
      final row = run.cloudFolders[local.id];
      if (row == null || row['purged_at'] != null || local.cloudRevision != null) continue;
      if (await _dbService.hasPendingSyncAction(entityType: 'folder', entityId: local.id)) continue;
      final revision = row['revision'] as int?;
      if (_sameFolderFields(local, row)) {
        await _dbService.upsertFolder(local.copyWith(cloudRevision: revision));
      } else if (local.updatedAt.isAfter(DateTime.parse(row['updated_at'] as String))) {
        await _dbService.upsertFolder(local.copyWith(cloudRevision: revision));
        await _dbService.queueSyncAction(
          entityType: 'folder',
          entityId: local.id,
          action: 'upsert',
          payload: jsonEncode(local.toSupabaseJson(run.userId)),
        );
        _start(full: false);
      } else {
        run.forcedFolders.add(local.id);
      }
    }
  }

  /// Whether a local note has the fields the device sends for it, as the cloud row has them.
  static bool _sameNoteFields(Note local, Map<String, dynamic> row) => _sameCloudFields(
        _notePushRow(local.toSupabaseJson('')),
        row,
        values: const ['title', 'content', 'folder_id', 'tags', 'is_pinned', 'is_locked', 'is_deleted'],
        dates: const ['deleted_at', 'created_at', 'updated_at'],
      );

  /// Whether a local folder has the fields the device sends for it, as the cloud row has them.
  static bool _sameFolderFields(Folder local, Map<String, dynamic> row) => _sameCloudFields(
        local.toSupabaseJson(''),
        row,
        values: const ['name', 'parent_id', 'icon', 'is_system'],
        dates: const ['created_at', 'updated_at'],
      );

  static bool _sameCloudFields(
    Map<String, dynamic> sent,
    Map<String, dynamic> row, {
    required List<String> values,
    required List<String> dates,
  }) {
    for (final key in values) {
      if (jsonEncode(sent[key]) != jsonEncode(row[key])) return false;
    }
    for (final key in dates) {
      final sentAt = sent[key] == null ? null : DateTime.parse(sent[key] as String);
      final cloudAt = row[key] == null ? null : DateTime.parse(row[key] as String);
      if (sentAt == null || cloudAt == null) {
        if (sentAt != cloudAt) return false;
      } else if (!sentAt.isAtSameMomentAs(cloudAt)) {
        return false;
      }
    }
    return true;
  }

  /// Sends the never-synced notes (Model: Sending unsynced notes), except set-aside ones and those the cloud refused.
  Future<void> _sendUnsyncedNotes(_SyncRun run) async {
    final setAside = await _dbService.getSetAsideNoteIds();
    for (final note in await _dbService.getNotes(isDeleted: null)) {
      run.checkDeadline();
      if (note.syncedAt != null || setAside.contains(note.id) || run.refusedNotes.contains(note.id)) continue;
      await _sendUnsyncedNote(run, note.id);
    }
  }

  /// Sends one never-synced note (Model: Sending unsynced notes). A welcome note is removed instead when the cloud already
  /// has notes. The note is queued as a save before it is sent, so a refusal by the cloud is counted on that item like the
  /// refusal of any queued change, and the run goes on. The item is removed when the cloud accepts the note, which is
  /// then marked as synced at that moment, on the revision the cloud gave it.
  Future<void> _sendUnsyncedNote(_SyncRun run, String noteId) async {
    var current = await _dbService.getNoteById(noteId);
    while (current != null && current.syncedAt == null) {
      if (isWelcomeNote(current) && await _cloudHasNotes(run)) {
        await _dbService.permanentlyDeleteNote(current.id);
        await _vaultService.deleteNoteFileIfUnused(_dbService, current.filePath);
        _remoteChanges.add(SampleNoteDiscarded(current.id));
        return;
      }
      final sent = current;
      await _uploadMissingAttachments(run, sent.content);
      // A change of the note already queued is the one counted on; otherwise the save is queued now.
      if (!await _dbService.hasPendingSyncAction(entityType: 'note', entityId: noteId)) {
        await _dbService.queueSyncAction(
          entityType: 'note',
          entityId: noteId,
          action: 'upsert',
          payload: jsonEncode(sent.toSupabaseJson(run.userId)),
        );
      }
      final item = (await _dbService.getPendingSyncActions()).firstWhere(
        (queued) => queued['entity_type'] == 'note' && queued['entity_id'] == noteId,
      );
      final _PushOutcome outcome;
      try {
        outcome = await _pushRow(
          run,
          table: 'notes',
          row: _notePushRow(sent.toSupabaseJson(run.userId)),
          baseRevision: sent.cloudRevision,
          localTime: sent.updatedAt,
        );
      } on PostgrestException catch (error) {
        // Refused by the cloud: counted on the queued item, which is set aside after the third refusal in a row.
        if (!isCloudRejection(error)) rethrow;
        debugPrint('Unsynced note refused: ${error.message}');
        run.refusedNotes.add(noteId);
        await _dbService.recordRejectedSyncAction(item, error.message);
        return;
      }
      switch (outcome) {
        case _Accepted(:final revision):
          run.pushedNotes.add(noteId);
          await _dbService.removeSyncActionIfUnchanged(item);
          final stored = await _dbService.getNoteById(noteId);
          if (stored == null) return;
          if (stored.updatedAt.isAtSameMomentAs(sent.updatedAt)) {
            await _dbService.upsertNote(stored.copyWith(syncedAt: DateTime.now(), cloudRevision: revision));
            return;
          }
          // Edited while the send was in flight: the cloud has this version, and the newer one is sent on its revision.
          await _dbService.upsertNote(stored.copyWith(cloudRevision: revision));
          current = stored;
          break;
        case _CloudWon(row: final cloud):
          await _dbService.removeSyncActionIfUnchanged(item);
          if (cloud['purged_at'] != null) {
            await _removeRemoteNote(noteId, revision: _recordRevision(cloud));
          } else {
            run.keepNote(cloud, forced: true);
          }
          return;
        case _Gone():
          await _dbService.removeSyncActionIfUnchanged(item);
          return;
        case _Unsettled():
          return;
      }
    }
  }

  /// Whether the cloud has a note of the user that is not deleted for good. Read once per run, when a welcome note needs it.
  Future<bool> _cloudHasNotes(_SyncRun run) async {
    final known = run.cloudHasNotes;
    if (known != null) return known;
    final rows = await _cloud(
      run,
      () => run.client.from('notes').select('id').eq('user_id', run.userId).isFilter('purged_at', null).limit(1),
    );
    return run.cloudHasNotes = (rows as List).isNotEmpty;
  }

  /// Applies the cloud folders before the notes, so every pulled note finds its folder (Model: Pulling). A folder whose
  /// revision this device already has is not applied again; a deletion placeholder removes the folder.
  Future<void> _applyCloudFolders(_SyncRun run) async {
    for (final entry in run.cloudFolders.entries) {
      run.checkDeadline();
      final row = entry.value;
      if (row['purged_at'] != null) {
        await _removeRemoteFolder(entry.key, deletedAt: _recordTime(row), revision: _recordRevision(row));
        continue;
      }
      if (await _storeCloudFolder(Folder.fromSupabaseJson(row), force: run.forcedFolders.contains(entry.key))) {
        notifyListeners();
      }
    }
  }

  /// Applies the cloud notes (Model: Pulling). A note whose revision this device already has is not applied again.
  Future<void> _applyCloudNotes(_SyncRun run) async {
    for (final entry in run.cloudNotes.entries) {
      run.checkDeadline();
      final row = entry.value;
      if (row['purged_at'] != null) {
        await _removeRemoteNote(entry.key, deletedAt: _recordTime(row), revision: _recordRevision(row));
      } else {
        await applyRemoteNote(Note.fromSupabaseJson(row), force: run.forcedNotes.contains(entry.key));
      }
    }
  }

  /// Full check only (Requirements: Controllo completo). A local row this device had synced that the cloud no longer has
  /// is removed here without a queued change. Rows this run wrote are on the cloud already; the read did not see them.
  Future<void> _removeRowsMissingFromCloud(_SyncRun run) async {
    // The list read above came with the session; without it the rows are not removed.
    if (!run.hasSession) throw const _SignedOutDuringRun();
    for (final local in await _dbService.getNotes(isDeleted: null)) {
      run.checkDeadline();
      if (local.syncedAt == null || run.pushedNotes.contains(local.id) || run.fullNoteIds.contains(local.id)) continue;
      await _removeRemoteNote(local.id);
    }
    for (final local in await _dbService.getFolders()) {
      if (local.isSystem || run.pushedFolders.contains(local.id) || run.fullFolderIds.contains(local.id)) continue;
      if (await _dbService.hasPendingSyncAction(entityType: 'folder', entityId: local.id)) continue;
      await _rewriteNotesMovedFrom(local.id);
      await _dbService.deleteFolder(local.id);
      notifyListeners();
      _remoteChanges.add(CloudFolderRemoved(local.id));
    }
  }

  /// Uploads the attachments of notes already in the cloud that the cloud still lacks: an upload that failed on an
  /// earlier run is tried again.
  Future<void> _uploadAttachmentsOfSyncedNotes(_SyncRun run) async {
    for (final note in await _dbService.getNotes(isDeleted: null)) {
      if (note.syncedAt != null) await _uploadMissingAttachments(run, note.content);
    }
  }

  /// Uploads the attachments of [content] that the cloud does not have yet, to the user's folder in the bucket. A failed
  /// upload is logged and tried again by the next run; a timeout fails the run (Model: sync-run FAILED).
  Future<void> _uploadMissingAttachments(_SyncRun run, String content) async {
    for (final ref in attachmentRefs(content)) {
      if (run.cloudAttachments.contains(ref)) continue;
      final file = _vaultService.resolveAttachment(ref);
      if (!await file.exists()) continue;
      try {
        await _cloud(
          run,
          () => run.client.storage
              .from(_attachmentBucket)
              .upload('${run.userId}/${_attachmentName(ref)}', file, fileOptions: const FileOptions(upsert: true)),
        );
        run.cloudAttachments.add(ref);
        await _dbService.addCloudAttachment(ref);
      } catch (error) {
        if (error is TimeoutException) rethrow;
        await _log?.record(category: 'attachmentUpload', detail: '$ref: $error');
      }
    }
  }

  /// Downloads the attachments of every note that are missing from the vault. A failed download is logged and tried again
  /// by the next run; a timeout fails the run.
  Future<void> _downloadAttachmentsOfAllNotes(_SyncRun run) async {
    for (final note in await _dbService.getNotes(isDeleted: null)) {
      await _downloadMissingAttachments(run, note.content);
    }
  }

  /// Downloads the attachments that [content] refers to and that are missing from the vault. A failed download is logged
  /// and tried again by the next run; a timeout fails the caller.
  Future<void> _downloadMissingAttachments(_SyncRun run, String content) async {
    for (final ref in attachmentRefs(content)) {
      final file = _vaultService.resolveAttachment(ref);
      if (await file.exists()) continue;
      try {
        final bytes = await _cloud(
          run,
          () => run.client.storage.from(_attachmentBucket).download('${run.userId}/${_attachmentName(ref)}'),
        );
        await file.writeAsBytes(bytes);
        run.cloudAttachments.add(ref);
        await _dbService.addCloudAttachment(ref);
      } catch (error) {
        if (error is TimeoutException) rethrow;
        await _log?.record(category: 'attachmentDownload', detail: '$ref: $error');
      }
    }
  }

  /// The file name of an attachment inside the user's folder in the bucket.
  static String _attachmentName(String ref) => ref.substring('attachments/'.length);

  /// Removes the bucket files of a deleted note that no other cloud note uses; a failure other than a timeout is logged.
  Future<void> _removeUnusedAttachmentsSafely(_SyncRun run, String deletedContent) async {
    try {
      await _cloud(run, () => _removeUnusedAttachments(run.client, run.userId, deletedContent));
    } catch (error) {
      if (error is TimeoutException) rethrow;
      debugPrint('Attachment removal failed: $error');
    }
  }

  /// Runs one request to the cloud within [requestTimeout], and never past the deadline of the run (Requirements: tempi massimi).
  /// A run whose session has ended sends no request: it stops instead.
  Future<T> _cloud<T>(_SyncRun run, Future<T> Function() request) {
    if (!run.hasSession) return Future<T>.error(const _SignedOutDuringRun());
    final left = run.deadline.difference(DateTime.now());
    if (left <= Duration.zero) return Future<T>.error(TimeoutException('sync run'));
    return request().timeout(left < requestTimeout ? left : requestTimeout);
  }

  /// Starts a sync run requested by the user: "Sincronizza Adesso" and pulling to refresh. It is a full check, and it runs
  /// even while the system reports no connection. The future completes when the run has ended, or at once when the
  /// request was remembered for a run in progress that is still running.
  Future<void> syncNow() => _start(full: true, startsOffline: true);

  /// Reads every row through [fetchPage] (rows `from`..`to`, inclusive), one page per request, until a
  /// short page. The server caps each response at one page (1000 rows by default).
  @visibleForTesting
  static Future<List<Map<String, dynamic>>> readAllPages(
    Future<List> Function(int from, int to) fetchPage, {
    int pageSize = 1000,
  }) async {
    final rows = <Map<String, dynamic>>[];
    for (var from = 0;; from += pageSize) {
      final page = await fetchPage(from, from + pageSize - 1);
      rows.addAll(page.cast<Map<String, dynamic>>());
      if (page.length < pageSize) return rows;
    }
  }

  /// Sample welcome notes created on first launch, identified by their exact title.
  static bool isWelcomeNote(Note note) =>
      note.title == 'Benvenuto in OpenNotes' || note.title == 'Pianificazione & Attività';

  /// Queues note change for syncing.
  Future<void> notifyNoteChanged(Note note, {bool isDelete = false}) async {
    final user = currentUser;
    // Never-synced welcome notes: their saves stay local (the next sync run decides their fate, in its unsynced sweep).
    // Their permanent deletion is queued like any other.
    if (!isDelete && note.syncedAt == null && isWelcomeNote(note)) return;
    if (isDelete) {
      await _dbService.queueSyncAction(
        entityType: 'note',
        entityId: note.id,
        action: 'delete',
        payload: jsonEncode({'id': note.id}),
      );
    } else {
      final payload = note.toSupabaseJson(user?.id ?? '');
      await _dbService.queueSyncAction(
        entityType: 'note',
        entityId: note.id,
        action: 'upsert',
        payload: jsonEncode(payload),
      );
    }

    await _refreshPendingChangeCount();
    if (isAuthenticated) {
      // Fire-and-forget sync attempt
      _start(full: false);
    }
  }

  /// Queues folder change for syncing (creation, rename or deletion).
  Future<void> notifyFolderChanged(Folder folder, {bool isDelete = false}) async {
    final user = currentUser;
    if (isDelete) {
      // The delete takes the place of a queued creation or rename of the folder: only the delete is sent.
      await _dbService.queueSyncAction(
        entityType: 'folder',
        entityId: folder.id,
        action: 'delete',
        payload: jsonEncode({'id': folder.id}),
      );
    } else {
      await _dbService.queueSyncAction(
        entityType: 'folder',
        entityId: folder.id,
        action: 'upsert',
        payload: jsonEncode(folder.toSupabaseJson(user?.id ?? '')),
      );
    }

    await _refreshPendingChangeCount();
    if (isAuthenticated) {
      // Fire-and-forget sync attempt
      _start(full: false);
    }
  }

  /// The user chose "Riprova" on a set-aside change (Model: user.RETRY_SET_ASIDE_CHANGE): it is queued again at its
  /// place with its rejections cleared, and a run is asked. False when the change is not set aside.
  Future<bool> retrySetAsideChange(String entityType, String entityId) async {
    if (!await _dbService.retrySetAsideSyncAction(entityType, entityId)) return false;
    await _refreshPendingChangeCount();
    await _start(full: false);
    return true;
  }

  /// The user chose "Usa la versione del cloud" on a set-aside change (Model: user.USE_CLOUD_VERSION). Offered only when
  /// the cloud has a copy that is not deleted: the local change is dropped and a run applies that copy, even when its
  /// revision is already known. False when the cloud has no such copy or the change is not set aside.
  Future<bool> useCloudVersion(String entityType, String entityId) async {
    final client = _client;
    if (client == null || currentUser == null) return false;
    final table = entityType == 'folder' ? 'folders' : 'notes';
    final cloudRow = await client.from(table).select('purged_at').eq('id', entityId).maybeSingle().timeout(requestTimeout);
    if (cloudRow == null || cloudRow['purged_at'] != null) return false;
    if (!await _dbService.removeSetAsideSyncAction(entityType, entityId)) return false;
    if (entityType == 'note') {
      _noteVersionRequests.add(entityId);
    } else {
      _folderVersionRequests.add(entityId);
    }
    await _refreshPendingChangeCount();
    await _start(full: false);
    return true;
  }

  /// The changes the sync has set aside, oldest first, for the settings window. The title is the local note or folder
  /// name, else the cloud one, else the id. A cloud copy counts only when the cloud row is not a deleted placeholder;
  /// when the cloud cannot be asked now, no copy is counted.
  Future<List<SetAsideChange>> setAsideChanges() async {
    final client = _client;
    final changes = <SetAsideChange>[];
    for (final row in await _dbService.getSetAsideSyncActions()) {
      final entityType = row['entity_type'] as String;
      final entityId = row['entity_id'] as String;
      final isFolder = entityType == 'folder';
      final localTitle = isFolder
          ? (await _dbService.getFolderById(entityId))?.name
          : (await _dbService.getNoteById(entityId))?.title;
      String? cloudTitle;
      var cloudHasCopy = false;
      if (client != null && currentUser != null) {
        try {
          final cloudRow = await client
              .from(isFolder ? 'folders' : 'notes')
              .select('${isFolder ? 'name' : 'title'}, purged_at')
              .eq('id', entityId)
              .maybeSingle()
              .timeout(requestTimeout);
          if (cloudRow != null) {
            cloudTitle = cloudRow[isFolder ? 'name' : 'title'] as String?;
            cloudHasCopy = cloudRow['purged_at'] == null;
          }
        } catch (_) {
          // Cloud unreachable now: its copy is not offered, the local change still is.
        }
      }
      changes.add(SetAsideChange(
        entityType: entityType,
        entityId: entityId,
        title: localTitle ?? cloudTitle ?? entityId,
        cloudHasCopy: cloudHasCopy,
      ));
    }
    return changes;
  }

  /// Recounts the queued changes not set aside and notifies the listeners, so the settings window shows the new count.
  Future<void> _refreshPendingChangeCount() async {
    final items = await _dbService.getPendingSyncActions();
    _pendingChangeCount = items.where((item) => item['set_aside'] == 0).length;
    _setAsideCount = items.where((item) => item['set_aside'] == 1).length;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _triggerSub?.cancel();
    _realtimeChannel?.unsubscribe();
    _remoteChanges.close();
    super.dispose();
  }

  /// Rewrites the date fields of a queued payload as UTC instants with the zone suffix. Payloads
  /// queued before the fix hold local dates without a zone, which [DateTime.parse] reads as local time.
  static void _toCloudUtc(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is String) payload[key] = DateTime.parse(value).toUtc().toIso8601String();
    }
  }
}
