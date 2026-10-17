import 'dart:io';
import 'package:flutter/foundation.dart';

/// The app log of sync failures: a text file in the app documents folder, kept across launches (Model: sync-run
/// FAILED; Requirements: rules#sync-run). Each entry is a line with the date, the category and the technical detail;
/// continuation lines of a detail are indented. The file keeps only the most recent [maxEntries] entries.
class SyncLog {
  /// Entries kept in the file; the oldest are dropped first.
  static const int maxEntries = 500;

  final File file;
  Future<void> _writes = Future<void>.value();

  SyncLog(this.file);

  /// Appends one entry. Writes are done one after the other; a failure to write is reported to the debug console only,
  /// so that it never fails the sync.
  Future<void> record({required String category, required Object detail, DateTime? at}) {
    final when = (at ?? DateTime.now()).toIso8601String();
    final text = detail.toString().split('\n').join('\n  ');
    final entry = '$when [$category] $text\n';
    _writes = _writes.then((_) => _append(entry)).catchError((Object error) {
      debugPrint('Sync log write failed: $error');
    });
    return _writes;
  }

  /// Reads the entries as text, empty when nothing was recorded yet.
  Future<String> read() async {
    await _writes;
    if (!await file.exists()) return '';
    return file.readAsString();
  }

  Future<void> _append(String entry) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(entry, mode: FileMode.append, flush: true);
    final lines = await file.readAsLines();
    final starts = [for (var i = 0; i < lines.length; i++) if (_isEntryStart(lines[i])) i];
    if (starts.length <= maxEntries) return;
    final keepFrom = starts[starts.length - maxEntries];
    await file.writeAsString('${lines.sublist(keepFrom).join('\n')}\n', flush: true);
  }

  /// An entry starts on a line that is not indented.
  static bool _isEntryStart(String line) => line.isNotEmpty && line[0] != ' ';
}
