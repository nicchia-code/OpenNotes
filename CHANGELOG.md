# Changelog

## 0.1.0 - 2026-10-17
- Requires the Supabase migration `supabase/migrations/20261017131833_cloud_revisions.sql`, applied to the project before this release is used. Clients older than 0.1.0 can no longer write to the cloud and must be updated.
- Changed sync runs: each run reads only the rows changed since the last revision (a full check while none is known, or when one is asked for), saves carry the revision they are based on, requests made during a run start one further run, and each request to the cloud and each run have a time limit.
- Fixed the editor: a checkbox marker with no space after it (`[ ]text`) stays plain text for Enter, Tab, Backspace, the checklist button, and taps.
- Fixed the native launch window size: 1280 × 760 on Linux, Windows, and macOS.
- Fixed the checklist button and the text style menu: all leading symbols of a line are replaced, not only the first.
- Fixed loading: a checkbox marker with no text after it (`[ ]`, `- [x]`) opens as a checklist item.
- Added shared note actions on desktop and mobile, including duplicate, move, trash, restore, and confirmed permanent deletion.
- Added undo for moving notes to Trash and fixed sync queueing for permanent deletions without a vault file.
- Fixed vault file failures: a note action whose file cannot be written or removed is cancelled, the database and sync stay as they were, and a warning says the note was not saved; moving a note to Trash writes its file before the database.
- Fixed rich-text formatting drift and line-style reconciliation after edits, including deletion, line-start Enter, and Markdown shortcuts.
- Corrected legacy prefix offset mapping and sanitized persisted formatting ranges when notes load.
- Preserved inline spans and the surviving line style when text blocks merge.
- Fixed sync and account behaviour: local notes follow the signed-in account, offline folder changes no longer overwrite a newer cloud copy, and images and drawings are uploaded and downloaded with their notes.
- Fixed sync: a queued note save older than the cloud copy no longer overwrites it; the newer cloud version is kept.
- Fixed vault files: a renamed note moves its file, and a pending save no longer overwrites changes made during the wait.
- Fixed note search and tags: `_` and `%` are literal, accented capitals match, and accented tag letters are accepted.
- Fixed mobile and desktop navigation: the editor shows the last received version, the lock button asks for the PIN, the trash has no New note button, and the editor menu no longer offers permanent deletion for restored notes.
- Fixed the desktop editor: the open note now receives remote changes, and its date and tags update after each edit.
- Fixed the editor: bullets from the text style menu follow the indent level, the active part follows the cursor into a table, and the Markdown export message shows the saved file name.
- Fixed Google sign-in return: the `opennotes://login-callback` link is registered on Android, iOS, macOS, Linux, and Windows, so the browser can bring the user back to the app.
