import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';
import 'database_service.dart';
import 'vault_service.dart';

/// A change the cloud sync made to the local copy, emitted on [SyncService.remoteChanges].
sealed class RemoteChange {
  const RemoteChange();
}

/// CLOUD_NOTE_APPLIED: a cloud note created or replaced the local copy.
final class CloudNoteApplied extends RemoteChange {
  final String noteId;
  const CloudNoteApplied(this.noteId);
}

/// CLOUD_NOTE_REMOVED: a note removed from this device by the cloud: a realtime delete, or a removal made by a sync run (account change, discarded welcome note, note deleted in the cloud).
final class CloudNoteRemoved extends RemoteChange {
  final String noteId;
  const CloudNoteRemoved(this.noteId);
}

/// A local folder was removed or changed by the cloud; the Model names no folder event, so lists just reload.
final class CloudFolderChanged extends RemoteChange {
  const CloudFolderChanged();
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
  StreamSubscription<AuthState>? _authSubscription;
  /// True only while the app waits for the browser to return from Google sign-in (Model: Awaiting login).
  bool _awaitingLogin = false;
  String? _signInError;
  bool _supabasePrepared = false;
  final StreamController<RemoteChange> _remoteChanges = StreamController<RemoteChange>.broadcast();

  SyncService(this._dbService, this._vaultService);

  bool get isConfigured => _isConfigured;
  bool get isSyncing => _isSyncing;
  String? get supabaseUrl => _supabaseUrl;
  String? get supabaseAnonKey => _supabaseAnonKey;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  bool get isAwaitingLogin => _awaitingLogin;
  void setAwaitingLogin(bool value) {
    _awaitingLogin = value;
    if (value) _signInError = null;
  }

  /// Message of the last sign-in return that carried an error (e.g. the user cancelled), received through the app link.
  String? get signInError => _signInError;

  /// Emits when a cloud change has been applied to or removed from the local copy: a note stored
  /// ([CloudNoteApplied]), a note removed ([CloudNoteRemoved]) or a folder changed. Listeners reload their
  /// lists on each event, even while a full sync is running.
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

  /// Prepares the cloud connection from the build variables only; nothing is read from device storage.
  Future<void> init() async {
    if (missingBuildVariables.isNotEmpty) return;
    await initializeSupabase(_buildSupabaseUrl.trim(), _buildSupabaseAnonKey.trim());
  }

  /// Dynamically initializes Supabase client.
  Future<bool> initializeSupabase(String url, String anonKey) async {
    try {
      _isSyncing = true;
      notifyListeners();

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

      if (isAuthenticated) {
        _setupRealtimeSubscription();
        // syncNow takes the flag itself and keeps it until the startup sync has finished.
        _isSyncing = false;
        await syncNow();
      } else {
        _isSyncing = false;
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('Error initializing Supabase: $e');
      _isSyncing = false;
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

      if (session != null &&
          (event == AuthChangeEvent.initialSession ||
           event == AuthChangeEvent.signedIn)) {
        _awaitingLogin = false;
        _signInError = null;
        _setupRealtimeSubscription();
        await syncNow();
      } else if (session != null && event == AuthChangeEvent.tokenRefreshed) {
        // A renewed session starts a sync run, as the Model says, and Realtime is closed and reopened
        // so the channel carries the new token.
        _awaitingLogin = false;
        _setupRealtimeSubscription();
        await syncNow();
      } else if (event == AuthChangeEvent.signedOut) {
        _realtimeChannel?.unsubscribe();
        _realtimeChannel = null;
        notifyListeners();
      }
    }, onError: (Object error, StackTrace stackTrace) {
      // The return through the app link carried an error (e.g. the user cancelled): the account stays signed out,
      // and the error is shown in the settings window.
      debugPrint('SyncService sign-in error: $error');
      _awaitingLogin = false;
      _signInError = error is AuthException ? error.message : error.toString();
      notifyListeners();
    });
  }

  /// Sets up Realtime WebSocket listener for notes and folders.
  void _setupRealtimeSubscription() {
    final client = _client;
    final user = currentUser;
    if (client == null || user == null) return;

    _realtimeChannel?.unsubscribe();
    _realtimeChannel = client.channel('public:notes_sync');

    _realtimeChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) async {
            debugPrint('Realtime change received for notes: ${payload.eventType}');
            await handleRemoteNoteChange(payload);
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
          callback: (payload) async {
            debugPrint('Realtime change received for folders: ${payload.eventType}');
            await handleRemoteFolderChange(payload);
          },
        )
        .subscribe();
  }

  /// Applies a realtime note change to the local copy.
  Future<void> handleRemoteNoteChange(PostgresChangePayload payload) async {
    final eventType = payload.eventType;
    if (eventType == PostgresChangeEvent.delete) {
      final oldRecord = payload.oldRecord;
      final id = oldRecord['id'] as String?;
      if (id != null) {
        final local = await _dbService.getNoteById(id);
        await _dbService.permanentlyDeleteNote(id);
        await _vaultService.deleteNoteFileIfUnused(_dbService, local?.filePath);
        _remoteChanges.add(CloudNoteRemoved(id));
      }
      return;
    }

    final record = payload.newRecord;
    if (record.isNotEmpty) {
      await applyRemoteNote(Note.fromSupabaseJson(record));
    }
  }

  /// Stores a cloud note over the local copy when the local copy is not newer and no delete of the note is queued.
  /// The download writes the vault file from the cloud title; when the title changed, the
  /// previous file stays in the vault as a copy that is no longer updated. Emits [remoteChanges] after each
  /// stored note, so the lists and an open editor update during a full sync too.
  /// Returns whether the cloud version was stored.
  Future<bool> applyRemoteNote(Note remoteNote) async {
    final localNote = await _dbService.getNoteById(remoteNote.id);
    if (localNote != null && localNote.updatedAt.isAfter(remoteNote.updatedAt)) {
      return false;
    }
    final client = _client;
    final user = currentUser;
    // A cloud note can point at a folder this device no longer has (deleted here or elsewhere);
    // keep it in the default folder instead of letting it vanish from every folder view.
    final folderId = await _dbService.folderExists(remoteNote.folderId)
        ? remoteNote.folderId
        : Folder.defaultNotesId;
    final downloaded = remoteNote.copyWith(folderId: folderId);
    // A queued delete wins unless the cloud changed the note after the delete was queued; then the cloud
    // version replaces the note and the queued delete is dropped. Otherwise the next sync run sends the delete.
    // ponytail: a delete queued during the file write below still lands; re-check after the write if that race matters.
    final deleteQueuedAt = await _dbService.pendingDeleteQueuedAt('note', remoteNote.id);
    if (deleteQueuedAt != null) {
      if (!remoteNote.updatedAt.isAfter(deleteQueuedAt)) return false;
      await _dbService.removeSyncActionsFor('note', remoteNote.id, action: 'delete');
    }
    // Attachments are downloaded only when the cloud version replaces the local copy.
    if (client != null && user != null) {
      await _downloadAttachments(client, user.id, remoteNote.content);
    }
    final saved = downloaded.copyWith(filePath: await _vaultService.saveNote(downloaded));
    await _dbService.upsertNote(saved);
    _remoteChanges.add(CloudNoteApplied(remoteNote.id));
    return true;
  }

  /// Vault attachment paths (`attachments/<file>`) that a note's content refers to.
  static Set<String> attachmentRefs(String content) =>
      _attachmentRef.allMatches(content).map((m) => m.group(0)!).toSet();

  /// Uploads the attachments of [content] to the account's folder in the bucket.
  /// ponytail: re-uploads on every push; upload only missing files if bandwidth matters.
  Future<void> _uploadAttachments(SupabaseClient client, String userId, String content) async {
    for (final ref in attachmentRefs(content)) {
      final file = _vaultService.resolveAttachment(ref);
      if (!await file.exists()) continue;
      await client.storage
          .from(_attachmentBucket)
          .upload('$userId/${ref.substring('attachments/'.length)}', file,
              fileOptions: const FileOptions(upsert: true));
    }
  }

  /// Downloads the attachments of [content] missing from the vault. A failed download
  /// is logged and retried by the next sync, so the note text still arrives.
  Future<void> _downloadAttachments(SupabaseClient client, String userId, String content) async {
    for (final ref in attachmentRefs(content)) {
      final file = _vaultService.resolveAttachment(ref);
      if (await file.exists()) continue;
      try {
        final bytes = await client.storage
            .from(_attachmentBucket)
            .download('$userId/${ref.substring('attachments/'.length)}');
        await file.writeAsBytes(bytes);
      } catch (e) {
        debugPrint('Attachment download failed for $ref: $e');
      }
    }
  }

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
      if (id != null) {
        await _dbService.deleteFolder(id);
        // Deleted in the cloud: the local folder goes, but a change still queued for it stays. The next sync sends it
        // (Model: a queued folder rename is always sent), which recreates the folder in the cloud.
        notifyListeners();
        _remoteChanges.add(const CloudFolderChanged());
      }
      return;
    }

    final record = payload.newRecord;
    if (record.isNotEmpty) {
      final remoteFolder = Folder.fromSupabaseJson(record);
      // A folder deleted here whose delete is still queued: the cloud version wins only if the cloud changed it after
      // the delete was made (same rule as the full sync). Then the queued delete is dropped and the folder comes back;
      // otherwise the remote change is ignored and the next sync sends the delete.
      final deletedAt = await _dbService.getPendingSyncDeleteTime('folder', remoteFolder.id);
      if (deletedAt != null) {
        if (!remoteFolder.updatedAt.isAfter(deletedAt)) return;
        await _dbService.removePendingSyncDeletes('folder', remoteFolder.id);
      }
      await _dbService.upsertFolder(remoteFolder);
      notifyListeners();
      _remoteChanges.add(const CloudFolderChanged());
    }
  }

  /// Local notes belong to the account that synced them. When another account syncs,
  /// the notes it already uploaded are removed here together with their unsent changes
  /// (they come back with the previous account). Notes not yet uploaded are never
  /// dropped. Folders are never removed here: the download only stores or overwrites the folders
  /// the cloud has, and local folders it lacks stay (Model: the download never removes local folders).
  Future<void> _adoptAccount(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final owner = prefs.getString(_ownerKey);
    if (owner != null && owner != userId) {
      for (final note in await _dbService.getNotes(isDeleted: null)) {
        if (note.syncedAt == null) continue;
        await _dbService.permanentlyDeleteNote(note.id);
        await _vaultService.deleteNoteFileIfUnused(_dbService, note.filePath);
        await _dbService.removeSyncActionsFor('note', note.id);
        _remoteChanges.add(CloudNoteRemoved(note.id));
      }
    }
    await prefs.setString(_ownerKey, userId);
  }

  /// Sends one never-synced note, reading it again before each send. An edit made while an upload is in flight
  /// is sent again in the same run; the note is marked synced only after a send that left the stored copy
  /// unchanged. A welcome note is deleted instead of sent when the cloud has notes.
  Future<void> _sendUnsyncedNote(SupabaseClient client, String userId, String noteId,
      {required bool hasRemoteNotes}) async {
    var current = await _dbService.getNoteById(noteId);
    while (current != null && current.syncedAt == null) {
      if (hasRemoteNotes && isWelcomeNote(current)) {
        await _dbService.permanentlyDeleteNote(current.id);
        await _vaultService.deleteNoteFileIfUnused(_dbService, current.filePath);
        _remoteChanges.add(CloudNoteRemoved(current.id));
        return;
      }
      await _uploadAttachments(client, userId, current.content);
      await client.from('notes').upsert(current.toSupabaseJson(userId));
      final stored = await _dbService.getNoteById(noteId);
      if (stored == null) return;
      if (stored.updatedAt.isAtSameMomentAs(current.updatedAt)) {
        await _dbService.upsertNote(stored.copyWith(syncedAt: DateTime.now()));
        return;
      }
      current = stored;
    }
  }

  /// Triggers full bidirectional sync: pushes local queue & un-synced notes, pulls remote updates.
  Future<void> syncNow() async {
    final client = _client;
    final user = currentUser;
    if (client == null || user == null || _isSyncing) return;
    try {
      _isSyncing = true;
      notifyListeners();

      await _adoptAccount(user.id);

      // 1. Process local sync queue (Push changes)
      final queueItems = await _dbService.getPendingSyncActions();

      // The cloud copies as they were before this run sends anything. Queued changes are compared with
      // them, not with the copy this run has just written: its server time is newer than later queued changes.
      final cloudNotesBefore = <String, Map<String, dynamic>?>{};
      final cloudFoldersBefore = <String, Map<String, dynamic>?>{};
      final sentNoteIds = <String>{};
      final discardedNoteIds = <String>{};
      for (final item in queueItems) {
        final entityId = item['entity_id'] as String;
        if (item['entity_type'] == 'note' && !cloudNotesBefore.containsKey(entityId)) {
          cloudNotesBefore[entityId] = await client
              .from('notes')
              .select('content, updated_at')
              .eq('id', entityId)
              .maybeSingle();
        } else if (item['entity_type'] == 'folder' && !cloudFoldersBefore.containsKey(entityId)) {
          cloudFoldersBefore[entityId] = await client
              .from('folders')
              .select('updated_at')
              .eq('id', entityId)
              .maybeSingle();
        }
      }
      for (final item in queueItems) {
        final id = item['id'] as int;
        final entityType = item['entity_type'] as String;
        final action = item['action'] as String;
        final payload = jsonDecode(item['payload'] as String) as Map<String, dynamic>;

        if (entityType == 'note') {
          if (action == 'upsert') {
            // Saves of a note discarded earlier in this run, because the cloud deleted it, are dropped with it.
            if (discardedNoteIds.contains(item['entity_id'] as String)) {
              await _dbService.removeSyncAction(id);
              continue;
            }
            // Never-synced welcome note (renamed after the save was queued): the queued save is not sent.
            // Step 3 below deletes the note if the cloud has notes, otherwise sends its current version.
            final queuedNote = await _dbService.getNoteById(item['entity_id'] as String);
            if (queuedNote != null && queuedNote.syncedAt == null && isWelcomeNote(queuedNote)) {
              await _dbService.removeSyncAction(id);
              continue;
            }

            final cleanPayload = Map<String, dynamic>.from(payload)
              ..remove('file_path')
              ..remove('synced_at');
            cleanPayload['user_id'] = user.id;

            if (cleanPayload['tags'] is String) {
              try {
                cleanPayload['tags'] = jsonDecode(cleanPayload['tags'] as String);
              } catch (_) {
                cleanPayload['tags'] = [];
              }
            } else if (cleanPayload['tags'] == null) {
              cleanPayload['tags'] = [];
            }

            if (cleanPayload['is_pinned'] is int) {
              cleanPayload['is_pinned'] = cleanPayload['is_pinned'] == 1;
            }
            if (cleanPayload['is_locked'] is int) {
              cleanPayload['is_locked'] = cleanPayload['is_locked'] == 1;
            }
            if (cleanPayload['is_deleted'] is int) {
              cleanPayload['is_deleted'] = cleanPayload['is_deleted'] == 1;
            }
            _toCloudUtc(cleanPayload, ['deleted_at', 'created_at', 'updated_at']);

            // Last writer wins: a queued save not strictly newer than the cloud copy is dropped; the pull below brings the cloud version.
            final cloudRow = cloudNotesBefore[item['entity_id'] as String];
            final localUpdatedAt = DateTime.parse(payload['updated_at'] as String);
            final cloudUpdatedAt =
                cloudRow == null ? null : DateTime.tryParse(cloudRow['updated_at'] as String);
            // Deletion wins: a note the cloud no longer has, but this device had synced, was deleted elsewhere.
            // Its queued saves are discarded (permanentlyDeleteNote) and the note stays removed here. A note this
            // device never synced is sent even when it was deleted here: its queued delete then removes it from the cloud.
            final localNote = await _dbService.getNoteById(item['entity_id'] as String);
            final deletedInCloud = cloudRow == null &&
                !sentNoteIds.contains(item['entity_id'] as String) &&
                localNote != null &&
                localNote.syncedAt != null;
            if (deletedInCloud) {
              discardedNoteIds.add(item['entity_id'] as String);
              await _dbService.permanentlyDeleteNote(localNote.id);
              await _vaultService.deleteNoteFileIfUnused(_dbService, localNote.filePath);
              _remoteChanges.add(CloudNoteRemoved(localNote.id));
            } else if (cloudUpdatedAt == null || localUpdatedAt.isAfter(cloudUpdatedAt)) {
              await _uploadAttachments(client, user.id, cleanPayload['content'] as String);
              await client.from('notes').upsert(cleanPayload);
              // Deleted here while this upload was in flight: the upload is newer than the queued delete, so the
              // delete is applied now, not at the next run. ponytail: an upload already in flight is not cancelled.
              if (await _dbService.hasPendingSyncAction(
                  entityType: 'note',
                  entityId: item['entity_id'] as String,
                  action: 'delete',
                )) {
                await client.from('notes').delete().eq('id', item['entity_id'] as String);
              }
              sentNoteIds.add(item['entity_id'] as String);
              final sentNote = await _dbService.getNoteById(item['entity_id'] as String);
              if (sentNote != null) {
                await _dbService.upsertNote(sentNote.copyWith(syncedAt: DateTime.now()));
              }
            } else {
              // Discarded (Model: CHANGE_DISCARDED): the cloud copy is newer, so this save leaves the queue unsent
              // and the pull below brings the cloud version. Logged only: the user is not warned.
              debugPrint('Queued save of note ${item['entity_id']} discarded: the cloud copy is newer');
            }
          } else if (action == 'delete') {
            final id = item['entity_id'] as String;
            final cloudNote = cloudNotesBefore[id];
            // The cloud changed the note after this delete was queued: the delete is dropped and the
            // pull below brings the cloud note back. Otherwise the delete is sent.
            final cloudUpdatedAt =
                cloudNote == null ? null : DateTime.tryParse(cloudNote['updated_at'] as String);
            final deletedAt = DateTime.parse(item['created_at'] as String);
            if (cloudUpdatedAt == null || !cloudUpdatedAt.isAfter(deletedAt)) {
              await client.from('notes').delete().eq('id', id);
              if (cloudNote != null) {
                await _removeUnusedAttachments(client, user.id, cloudNote['content'] as String);
              }
            }
          }
        } else if (entityType == 'folder') {
          if (action == 'upsert') {
            // Model: a queued folder creation or rename is always sent, with no date comparison: it overwrites the cloud copy.
            final cleanFolderPayload = Map<String, dynamic>.from(payload);
            _toCloudUtc(cleanFolderPayload, ['created_at', 'updated_at']);
            // A parent deleted in the cloud (or here) is gone from the cloud: the foreign key would refuse the row and
            // block every later queue item. Send it top-level; the pull below makes it top-level here too. Local copy untouched.
            final parentId = cleanFolderPayload['parent_id'] as String?;
            if (parentId != null &&
                await client.from('folders').select('id').eq('id', parentId).maybeSingle() == null) {
              cleanFolderPayload['parent_id'] = null;
            }
            cleanFolderPayload['user_id'] = user.id;
            if (cleanFolderPayload['is_system'] is int) {
              cleanFolderPayload['is_system'] = cleanFolderPayload['is_system'] == 1;
            }
            await client.from('folders').upsert(cleanFolderPayload);
          } else if (action == 'delete') {
            final folderId = item['entity_id'] as String;
            final cloudRow = cloudFoldersBefore[folderId];
            // The cloud changed the folder after this delete was made: the delete is dropped and
            // the pull below brings the cloud folder back.
            final cloudUpdatedAt = cloudRow == null
                ? null
                : DateTime.tryParse(cloudRow['updated_at'] as String);
            final deletedAt = DateTime.parse(item['created_at'] as String);
            if (cloudUpdatedAt == null || !cloudUpdatedAt.isAfter(deletedAt)) {
              await client.from('folders').delete().eq('id', folderId);
            }
          }
        }

        await _dbService.removeSyncAction(id);
      }

      // 2. Fetch every remote note & folder, page by page
      final remoteNotesList = await readAllPages((from, to) async => await client
          .from('notes')
          .select()
          .eq('user_id', user.id)
          .order('id')
          .range(from, to) as List);
      final remoteFoldersList = await readAllPages((from, to) async => await client
          .from('folders')
          .select()
          .eq('user_id', user.id)
          .order('id')
          .range(from, to) as List);
      final hasRemoteNotes = remoteNotesList.isNotEmpty;

      // 3. Process un-synced local notes:
      // - If cloud already has notes, clean up un-synced default sample welcome notes
      // - Push any other local un-synced notes to Supabase so they are never lost
      final localNotes = await _dbService.getNotes(isDeleted: null);
      for (final lNote in localNotes) {
        if (lNote.syncedAt == null) {
          await _sendUnsyncedNote(client, user.id, lNote.id, hasRemoteNotes: hasRemoteNotes);
        }
      }

      // 4. Pull remote folders into local SQLite first, so every pulled note finds its folder
      for (final json in remoteFoldersList) {
        final remoteFolder = Folder.fromSupabaseJson(json);
        await _dbService.upsertFolder(remoteFolder);
      }

      // 5. Pull remote notes into local SQLite & Markdown Vault
      for (final json in remoteNotesList) {
        await applyRemoteNote(Note.fromSupabaseJson(json));
      }

      _lastSyncedAt = DateTime.now();
    } catch (e) {
      debugPrint('Sync error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

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
    // Never-synced welcome notes: their saves stay local (the next sync run decides their fate, syncNow step 3).
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

    if (isAuthenticated) {
      // Fire-and-forget sync attempt
      syncNow();
    }
  }

  /// Queues folder change for syncing (creation, rename or deletion).
  Future<void> notifyFolderChanged(Folder folder, {bool isDelete = false}) async {
    final user = currentUser;
    if (isDelete) {
      // Creations and renames still queued for this folder are dropped: only the delete is sent.
      await _dbService.removeSyncActionsFor('folder', folder.id);
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

    if (isAuthenticated) {
      // Fire-and-forget sync attempt
      syncNow();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
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
