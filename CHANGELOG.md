# Changelog

## 0.2.0 - 2026-10-17
- Added a sync app log: each failed sync run and each failed attachment upload or download is recorded with its date, category, and technical detail in `sync_log.txt` in the app documents folder, keeping the latest 500 entries.
- Fixed protected notes: duplicate, share, Markdown export, removing the lock, and permanent deletion decide the PIN from the stored lock state, not from the copy the menu or editor showed.
- Fixed the sign-in window when the device is offline at the return: it no longer announces a sync that never started, and the full check the sign-in asked for runs when the network returns.
- Fixed folder deletion: the vault copies of notes moved to Notes name Notes before the folder goes, and a failed write cancels the delete.
- Fixed sync of deletions: a queued folder or note delete wins over a cloud copy with the same time, and a folder delete is queued on the cloud revision the device saw, so the cloud does not discard it.
- Fixed sync error categories: cloud answers with a server error, 408, or 429 show as "cloud unavailable", and 401 as "session expired".
- Fixed sync runs: a run that passes its time limit while attachments transfer now fails and retries, instead of completing.
- Fixed sync after a full check: a local change queued by the check is sent by the run that follows, without waiting for the next interval.
- Changed the desktop sidebar: the sync status indicator replaces the settings gear, and without a connected account an "Accedi" command opens the cloud settings.
- Fixed the first sync of unsynced notes: a note the cloud refuses no longer fails the whole sync run; the refusal is counted like any refused change, and the run goes on.
- Fixed sync errors: a connection cut while the cloud answers is shown as "Rete non raggiungibile" instead of "Errore imprevisto".
- Fixed sync runs: a run that passes its time limit during local steps fails and retries, and no longer updates the last sync time.
- Fixed the sync order: attachments of notes already in the cloud are retried inside the queue step, so no attachment upload runs before the account check.

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
