import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/folder_model.dart';
import '../models/note_model.dart';
import 'database_service.dart';
import 'vault_service.dart';

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

  SyncService(this._dbService, this._vaultService);

  bool get isConfigured => _isConfigured;
  bool get isSyncing => _isSyncing;
  String? get supabaseUrl => _supabaseUrl;
  String? get supabaseAnonKey => _supabaseAnonKey;
  DateTime? get lastSyncedAt => _lastSyncedAt;

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

  static const String defaultSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://azbvjyvflrauysxcktji.supabase.co',
  );
  static const String defaultSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF6YnZqeXZmbHJhdXlzeGNrdGppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg4NjU4ODMsImV4cCI6MjEwNDQ0MTg4M30.6wawlQJuqaKwyiL0jxPoTquqhQqZF6TBGhx9bLsQINo',
  );

  /// Loads stored Supabase credentials from local storage.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _supabaseUrl = prefs.getString('supabase_url') ?? defaultSupabaseUrl;
    _supabaseAnonKey = prefs.getString('supabase_anon_key') ?? defaultSupabaseAnonKey;

    if (_supabaseUrl != null &&
        _supabaseAnonKey != null &&
        _supabaseUrl!.isNotEmpty &&
        _supabaseAnonKey!.isNotEmpty) {
      await initializeSupabase(_supabaseUrl!, _supabaseAnonKey!);
    }
  }

  /// Dynamically initializes Supabase client.
  Future<bool> initializeSupabase(String url, String anonKey) async {
    try {
      _isSyncing = true;
      notifyListeners();

      try {
        await Supabase.initialize(url: url.trim(), anonKey: anonKey.trim());
      } catch (e) {
        // If already initialized, it's fine
        debugPrint('Supabase already initialized or reinitializing: $e');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('supabase_url', url.trim());
      await prefs.setString('supabase_anon_key', anonKey.trim());

      _supabaseUrl = url.trim();
      _supabaseAnonKey = anonKey.trim();
      _isConfigured = true;

      _setupAuthListener();

      if (isAuthenticated) {
        _setupRealtimeSubscription();
        syncNow();
      }

      _isSyncing = false;
      notifyListeners();
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
          (event == AuthChangeEvent.signedIn ||
           event == AuthChangeEvent.tokenRefreshed ||
           event == AuthChangeEvent.initialSession)) {
        _setupRealtimeSubscription();
        await syncNow();
      } else if (event == AuthChangeEvent.signedOut) {
        _realtimeChannel?.unsubscribe();
        _realtimeChannel = null;
        notifyListeners();
      }
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
            await _handleRemoteNoteChange(payload);
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
            await _handleRemoteFolderChange(payload);
          },
        )
        .subscribe();
  }

  Future<void> _handleRemoteNoteChange(PostgresChangePayload payload) async {
    final eventType = payload.eventType;
    if (eventType == PostgresChangeEvent.delete) {
      final oldRecord = payload.oldRecord;
      final id = oldRecord['id'] as String?;
      if (id != null) {
        final localNote = await _dbService.getNoteById(id);
        await _dbService.permanentlyDeleteNote(id);
        if (localNote?.filePath != null) {
          await _vaultService.deleteNoteFile(localNote!.filePath!);
        }
        notifyListeners();
      }
      return;
    }

    final record = payload.newRecord;
    if (record.isNotEmpty) {
      final remoteNote = Note.fromSupabaseJson(record);
      final localNote = await _dbService.getNoteById(remoteNote.id);

      // Only update if remote is newer or does not exist locally
      if (localNote == null || !localNote.updatedAt.isAfter(remoteNote.updatedAt)) {
        await _dbService.upsertNote(remoteNote);
        await _vaultService.saveNote(remoteNote);
        notifyListeners();
      }
    }
  }

  Future<void> _handleRemoteFolderChange(PostgresChangePayload payload) async {
    final eventType = payload.eventType;
    if (eventType == PostgresChangeEvent.delete) {
      final oldRecord = payload.oldRecord;
      final id = oldRecord['id'] as String?;
      if (id != null) {
        await _dbService.deleteFolder(id);
        notifyListeners();
      }
      return;
    }

    final record = payload.newRecord;
    if (record.isNotEmpty) {
      final remoteFolder = Folder.fromSupabaseJson(record);
      await _dbService.upsertFolder(remoteFolder);
      notifyListeners();
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

      // 1. Process local sync queue (Push changes)
      final queueItems = await _dbService.getPendingSyncActions();
      for (final item in queueItems) {
        final id = item['id'] as int;
        final entityType = item['entity_type'] as String;
        final action = item['action'] as String;
        final payload = jsonDecode(item['payload'] as String) as Map<String, dynamic>;

        if (entityType == 'note') {
          if (action == 'upsert') {
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

            await client.from('notes').upsert(cleanPayload);
          } else if (action == 'delete') {
            await client.from('notes').delete().eq('id', item['entity_id']);
          }
        } else if (entityType == 'folder') {
          if (action == 'upsert') {
            final cleanFolderPayload = Map<String, dynamic>.from(payload);
            cleanFolderPayload['user_id'] = user.id;
            if (cleanFolderPayload['is_system'] is int) {
              cleanFolderPayload['is_system'] = cleanFolderPayload['is_system'] == 1;
            }
            await client.from('folders').upsert(cleanFolderPayload);
          } else if (action == 'delete') {
            await client.from('folders').delete().eq('id', item['entity_id']);
          }
        }

        await _dbService.removeSyncAction(id);
      }

      // 2. Fetch remote notes & folders
      final remoteNotesResponse = await client
          .from('notes')
          .select()
          .eq('user_id', user.id);

      final remoteFoldersResponse = await client
          .from('folders')
          .select()
          .eq('user_id', user.id);

      final remoteNotesList = remoteNotesResponse as List;
      final hasRemoteNotes = remoteNotesList.isNotEmpty;

      // 3. Process un-synced local notes:
      // - If cloud already has notes, clean up un-synced default sample welcome notes
      // - Push any other local un-synced notes to Supabase so they are never lost
      final localNotes = await _dbService.getNotes(isDeleted: null);
      for (final lNote in localNotes) {
        if (lNote.syncedAt == null) {
          final isSampleWelcomeNote = lNote.title == 'Benvenuto in OpenNotes' ||
              lNote.title == 'Pianificazione & Attività';

          if (hasRemoteNotes && isSampleWelcomeNote) {
            await _dbService.permanentlyDeleteNote(lNote.id);
            if (lNote.filePath != null) {
              await _vaultService.deleteNoteFile(lNote.filePath!);
            }
          } else {
            // Push to cloud
            final payload = lNote.toSupabaseJson(user.id);
            await client.from('notes').upsert(payload);
            await _dbService.upsertNote(lNote.copyWith(syncedAt: DateTime.now()));
          }
        }
      }

      // 4. Pull remote notes into local SQLite & Markdown Vault
      for (final json in remoteNotesList) {
        final remoteNote = Note.fromSupabaseJson(json as Map<String, dynamic>);
        final localNote = await _dbService.getNoteById(remoteNote.id);

        if (localNote == null || !localNote.updatedAt.isAfter(remoteNote.updatedAt)) {
          await _dbService.upsertNote(remoteNote);
          await _vaultService.saveNote(remoteNote);
        }
      }

      // 5. Pull remote folders into local SQLite
      for (final json in (remoteFoldersResponse as List)) {
        final remoteFolder = Folder.fromSupabaseJson(json as Map<String, dynamic>);
        await _dbService.upsertFolder(remoteFolder);
      }

      _lastSyncedAt = DateTime.now();
    } catch (e) {
      debugPrint('Sync error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Queues note change for syncing.
  Future<void> notifyNoteChanged(Note note, {bool isDelete = false}) async {
    final user = currentUser;
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

  @override
  void dispose() {
    _authSubscription?.cancel();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
