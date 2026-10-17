import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_notes/core/services/database_service.dart';
import 'package:open_notes/core/services/sync_service.dart';
import 'package:open_notes/core/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Own file: the Supabase client is a process-wide singleton.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the time of the last completed sync is restored from local preferences at startup', () async {
    final completedAt = DateTime.utc(2026, 10, 16, 14, 32);
    SharedPreferences.setMockInitialValues({
      SyncService.lastCompletedAtKey: completedAt.toIso8601String(),
    });
    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final vaultService = VaultService();
    await vaultService.init(customPath: (await Directory.systemTemp.createTemp('sync_last_time_vault_')).path);
    final syncService = SyncService(dbService, vaultService);
    addTearDown(syncService.dispose);

    expect(syncService.lastSyncedAt, isNull);
    await syncService.init();
    expect(syncService.lastSyncedAt, completedAt);
  });

  test('without a saved time the device has never completed a sync', () async {
    SharedPreferences.setMockInitialValues({});
    final dbService = DatabaseService();
    await dbService.init(inMemory: true);
    final vaultService = VaultService();
    await vaultService.init(customPath: (await Directory.systemTemp.createTemp('sync_last_time_vault_')).path);
    final syncService = SyncService(dbService, vaultService);
    addTearDown(syncService.dispose);

    await syncService.init();
    expect(syncService.lastSyncedAt, isNull);
  });
}
