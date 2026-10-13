---
column: done
technical: true
refs: []
drift: null
proposal: null
agent: false
created: 2026-10-13T15:27:25.675Z
finished: 2026-10-13T15:27:53.986Z
---
# Fix the failing cloud-note date test: stored date differs from the cloud date by the time zone

Test test/sync_deleted_folder_test.dart 'a cloud note whose folder is gone locally stays in Notes after download' fails: expected updatedAt 2026-10-02 09:00:00Z, actual 2026-10-02 11:00:00 (local time, +2h). Dates read from storage must denote the same instant as the cloud date (UTC vs local). Find whether the code or the test is wrong, fix it, keep the test meaningful (compare instants). Run test/sync_deleted_folder_test.dart and test/cloud_dates_test.dart.
