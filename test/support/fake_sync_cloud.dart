import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A cloud for the sync run tests, served on loopback the way PostgREST serves the notes and folders tables: reads
/// with their filters, and the compare-and-set writes of push_note and push_folder. Every stored row has a revision.
class FakeSyncCloud {
  FakeSyncCloud(this._server) {
    _server.listen(_handle);
  }

  final HttpServer _server;
  final Map<String, Map<String, dynamic>> notes = {};
  final Map<String, Map<String, dynamic>> folders = {};
  /// The `revision` filter of every read of the notes table, in order: `null` for a read of every row.
  final List<String?> noteReads = [];
  /// How many reads of the folders table there were: one per sync run.
  int folderReads = 0;
  /// Every note write the device attempted, in order: the note id and the base revision the device sent.
  final List<(String, int?)> noteWrites = [];
  /// Makes the next read of the notes table wait this long before it answers.
  Duration? delayNextNoteRead;
  /// Makes the next read of the notes table never answer.
  bool hangNextNoteRead = false;
  final Completer<void> _never = Completer<void>();
  /// Every attachment upload the device attempted, as the request path.
  final List<String> storageUploads = [];
  /// How many of the next attachment uploads the storage answers with a server error.
  int storageUploadsRefused = 0;
  /// Makes the next attachment upload never answer.
  bool hangNextStorageUpload = false;
  /// Note ids the cloud refuses to write, with a permission error.
  final Set<String> refusedNoteIds = {};
  int _revision = 100;

  int get port => _server.port;

  /// The revision of the last write the cloud accepted or stored.
  int get revision => _revision;

  int revisionOf(String id) => notes[id]!['revision'] as int;

  /// Stores a note as another device or the server left it, with the next revision.
  void putNote(Map<String, dynamic> row) => notes[row['id'] as String] = {...row, 'revision': ++_revision};

  /// Stores a folder as another device or the server left it, with the next revision.
  void putFolder(Map<String, dynamic> row) => folders[row['id'] as String] = {...row, 'revision': ++_revision};

  Future<void> close() => _server.close(force: true);

  /// The user the password sign-in route signs in as; set it before the sign-in.
  String? signInUserId;

  /// A row of the notes table, as the cloud returns it for [userId].
  static Map<String, dynamic> noteRow(String userId, String id, String title, DateTime updatedAt,
          {String content = '', DateTime? purgedAt}) =>
      {
        'id': id,
        'user_id': userId,
        'title': title,
        'content': content,
        'folder_id': 'notes',
        'tags': <String>[],
        'is_pinned': false,
        'is_locked': false,
        'is_deleted': false,
        'deleted_at': null,
        'created_at': DateTime.utc(2026, 10, 1).toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'purged_at': purgedAt?.toUtc().toIso8601String(),
      };

  Future<void> _handle(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    final response = request.response;
    final path = request.uri.path;
    response.headers.contentType = ContentType.json;
    if (path == '/rest/v1/rpc/push_note' || path == '/rest/v1/rpc/push_folder') {
      final isNote = path.endsWith('push_note');
      final call = jsonDecode(body) as Map<String, dynamic>;
      final row = Map<String, dynamic>.from(call[isNote ? 'p_note' : 'p_folder'] as Map<String, dynamic>);
      final id = row['id'] as String;
      final base = call['p_base_revision'] as int?;
      final table = isNote ? notes : folders;
      if (isNote) noteWrites.add((id, base));
      final current = table[id];
      if (isNote && refusedNoteIds.contains(id)) {
        response.statusCode = 400;
        response.write(jsonEncode({'message': 'permission denied for table notes', 'code': '42501'}));
      } else if (base != current?['revision']) {
        response.write(jsonEncode({'status': 'conflict', 'row': current}));
      } else {
        row['revision'] = ++_revision;
        table[id] = row;
        response.write(jsonEncode({'status': 'accepted', 'revision': _revision}));
      }
    } else if (path == '/rest/v1/notes' && request.method == 'GET') {
      noteReads.add(request.uri.queryParameters['revision']);
      final delay = delayNextNoteRead;
      delayNextNoteRead = null;
      if (delay != null) await Future<void>.delayed(delay);
      if (hangNextNoteRead) {
        hangNextNoteRead = false;
        await _never.future;
        return;
      }
      response.write(jsonEncode(_select(notes.values, request.uri.queryParameters)));
    } else if (path == '/rest/v1/folders' && request.method == 'GET') {
      folderReads++;
      response.write(jsonEncode(_select(folders.values, request.uri.queryParameters)));
    } else if (path.startsWith('/storage/v1/object/note-attachments/') && request.method == 'POST') {
      storageUploads.add(path);
      if (hangNextStorageUpload) {
        hangNextStorageUpload = false;
        await _never.future;
        return;
      }
      if (storageUploadsRefused > 0) {
        storageUploadsRefused--;
        response.statusCode = 500;
        response.write(jsonEncode({'message': 'unavailable'}));
      } else {
        response.write(jsonEncode({'Key': path}));
      }
    } else if (path == '/auth/v1/token' && request.uri.queryParameters['grant_type'] == 'password') {
      response.write(jsonEncode(sessionFor(signInUserId!)));
    } else if (path == '/auth/v1/logout') {
      response.statusCode = 204;
    } else {
      response.statusCode = 404;
    }
    await response.close();
  }

  /// The rows a read asks for: above `revision=gt.<n>` when given, with the `id` filter (`eq.<id>` or `in.(…)`), and
  /// live rows only for `purged_at=is.null`; in revision order.
  static List<Map<String, dynamic>> _select(Iterable<Map<String, dynamic>> rows, Map<String, String> query) {
    final since = query['revision'] == null ? null : int.parse(query['revision']!.replaceFirst('gt.', ''));
    final idParam = query['id'];
    final ids = idParam == null
        ? null
        : idParam.startsWith('in.(')
            ? idParam.substring(4, idParam.length - 1).split(',').map((id) => id.replaceAll('"', '')).toList()
            : [idParam.replaceFirst('eq.', '')];
    final live = query['purged_at'] == 'is.null';
    final selected = rows
        .where((row) =>
            (since == null || (row['revision'] as int) > since) &&
            (ids == null || ids.contains(row['id'])) &&
            (!live || row['purged_at'] == null))
        .toList();
    selected.sort((a, b) => (a['revision'] as int).compareTo(b['revision'] as int));
    return selected;
  }
}

/// The session JSON the Supabase client stores and restores for [userId], expiring in an hour.
Map<String, dynamic> sessionFor(String userId) {
  final expiresAt = DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000;
  return {
    'access_token': 'test-access',
    'token_type': 'bearer',
    'expires_in': 3600,
    'expires_at': expiresAt,
    'refresh_token': 'test-refresh',
    'user': {
      'id': userId,
      'aud': 'authenticated',
      'role': 'authenticated',
      'email': 'test@example.com',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'created_at': '2024-01-01T00:00:00Z',
    },
  };
}

/// Shared preferences of a signed-in user: the session the Supabase client restores when it starts.
Map<String, Object> signedInPreferences(String userId, {Map<String, Object> extra = const {}}) {
  return {
    'sb-127-auth-token': jsonEncode(sessionFor(userId)),
    ...extra,
  };
}

/// Waits until [condition] holds, polling every 10 ms, and fails the test after [timeout].
Future<void> waitUntil(bool Function() condition, {Duration timeout = const Duration(seconds: 10)}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) throw TimeoutException('condition not met', timeout);
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
