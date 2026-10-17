import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/services/sync_log.dart';

void main() {
  late Directory tempDir;
  late SyncLog log;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_log_test_');
    log = SyncLog(File('${tempDir.path}/sync_log.txt'));
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('reads empty before anything is recorded', () async {
    expect(await log.read(), isEmpty);
  });

  test('keeps each entry with its date, category and detail, and indents continuation lines', () async {
    await log.record(category: 'network', detail: 'SocketException: failed\nsecond line', at: DateTime.utc(2026, 10, 17, 9));
    await log.record(category: 'attachmentUpload', detail: 'attachments/a.png: refused', at: DateTime.utc(2026, 10, 17, 10));

    expect(
      await log.read(),
      '2026-10-17T09:00:00.000Z [network] SocketException: failed\n'
      '  second line\n'
      '2026-10-17T10:00:00.000Z [attachmentUpload] attachments/a.png: refused\n',
    );
  });

  test('survives a restart: a new instance on the same file reads the earlier entries', () async {
    await log.record(category: 'timeout', detail: 'TimeoutException', at: DateTime.utc(2026, 10, 17, 9));
    final afterRestart = SyncLog(File('${tempDir.path}/sync_log.txt'));

    expect(await afterRestart.read(), contains('[timeout] TimeoutException'));
  });

  test('keeps only the most recent entries', () async {
    for (var i = 0; i < SyncLog.maxEntries + 3; i++) {
      await log.record(category: 'unexpected', detail: 'failure $i', at: DateTime.utc(2026, 10, 17, 0, 0, i));
    }
    final text = await log.read();
    final entries = text.split('\n').where((line) => line.isNotEmpty && line[0] != ' ').toList();

    expect(entries, hasLength(SyncLog.maxEntries));
    expect(text, isNot(contains('failure 0\n')));
    expect(text, isNot(contains('failure 2\n')));
    expect(text, contains('failure 3\n'));
    expect(text, endsWith('failure ${SyncLog.maxEntries + 2}\n'));
  });
}
