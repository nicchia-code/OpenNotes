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

      _setupRealtimeSubscription();
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
        .subscribe();
  }

  Future<void> _handleRemoteNoteChange(PostgresChangePayload payload) async {
    final record = payload.newRecord;
    if (record.isNotEmpty) {
      final remoteNote = Note.fromSupabaseJson(record);
      final localNote = await _dbService.getNoteById(remoteNote.id);

      // Only update if remote is newer
      if (localNote == null || remoteNote.updatedAt.isAfter(localNote.updatedAt)) {
        await _dbService.upsertNote(remoteNote);
        await _vaultService.saveNote(remoteNote);
        notifyListeners();
      }
    }
  }

  /// Triggers full bidirectional sync: pushes local queue, pulls remote updates.
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

      // 2. Pull remote changes
      final remoteNotesResponse = await client
          .from('notes')
          .select()
          .eq('user_id', user.id);

      for (final json in remoteNotesResponse) {
        final remoteNote = Note.fromSupabaseJson(json);
        final localNote = await _dbService.getNoteById(remoteNote.id);

        if (localNote == null || remoteNote.updatedAt.isAfter(localNote.updatedAt)) {
          await _dbService.upsertNote(remoteNote);
          await _vaultService.saveNote(remoteNote);
        }
      }

      // Pull folders
      final remoteFoldersResponse = await client
          .from('folders')
          .select()
          .eq('user_id', user.id);

      for (final json in remoteFoldersResponse) {
        final remoteFolder = Folder.fromSupabaseJson(json);
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
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
