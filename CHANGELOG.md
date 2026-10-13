# Changelog

## Unreleased
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
