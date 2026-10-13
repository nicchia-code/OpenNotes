---
column: done
technical: true
refs: []
drift: null
proposal: null
agent: false
created: 2026-10-13T15:27:25.956Z
finished: 2026-10-13T15:29:24.351Z
---
# Fix the failing provider refresh test: notes list not refreshed when the sync service notifies

Test test/sync_service_test.dart 'NotesProvider automatically refreshes when SyncService notifies updates' fails: provider.notes.length is 0, expected 1, after dbService.upsertNote and syncService.notifyListeners(). Find whether the provider no longer reloads on sync notification (code bug) or the test is outdated (e.g. new reload conditions); fix the cause, do not weaken the assertion without reason. Run test/sync_service_test.dart and test/notes_provider_test.dart.
