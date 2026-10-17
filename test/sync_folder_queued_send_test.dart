import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/queued_folder_case.dart';

// Own file: the Supabase client is a process-wide singleton bound to the first test's server.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a queued folder rename older than a cloud change does not overwrite it', () async {
    final previousOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    addTearDown(() => HttpOverrides.global = previousOverrides);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    final c = await setUpQueuedFolderCase(
      server,
      cloudUpdatedAt: DateTime.utc(2026, 10, 1, 11),
      renamedAt: DateTime.utc(2026, 10, 1, 10),
    );
    await c.sync.syncNow();

    expect(c.cloud.folders['folder-1']!['name'], 'Nome cloud', reason: 'the cloud copy is newer: it is kept');
    expect((await c.db.getFolderById('folder-1'))!.name, 'Nome cloud',
        reason: 'the cloud version comes back with the download');
    expect(await c.db.getPendingSyncActions(), isEmpty);
  });
}
