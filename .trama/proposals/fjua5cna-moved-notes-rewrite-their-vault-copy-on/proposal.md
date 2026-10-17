---
status: rejected
base:
  notes/note.md: 40d57d03935cff2f1e3801a37ac9811e5ff575396be6f6a18e2bc5015fa317e3
delete: []
created: 2026-10-17T19:26:13.811Z
---
# Moved notes rewrite their vault copy on folder deletion

Le note spostate nella cartella Note da un'eliminazione di cartella hanno la copia nel vault riscritta con la nuova cartella: lo decide la Drift w5pmekbh (Task 4t38mgij), risolta con l'opzione «Riscrivere la copia di ogni nota spostata». Il Model della nota, però, nelle transizioni folder.DELETED e supabase.REMOTE_FOLDER_DELETED dice «senza riscrivere il file nell'archivio Markdown». Questa Proposal allinea quelle transizioni, anche per la nota nel cestino, alla decisione già presa: la copia nel vault viene riscritta con la cartella nuova. Scelte: la data di modifica resta invariata, la coda per il cloud resta com'è, e il vault-file non cambia perché la riscrittura è già descritta da note.SAVED. Il codice riscrive già le copie: questa Proposal non cambia il codice.

## Already present
- `note/Unpinned/folder.DELETED` — `lib/core/state/notes_provider.dart` (`deleteFolder`, `rewriteMovedNotes`)
- `note/Pinned/folder.DELETED` — `lib/core/state/notes_provider.dart` (`deleteFolder`, `rewriteMovedNotes`)
- `note/In trash/folder.DELETED` — `lib/core/state/notes_provider.dart` (`deleteFolder`, `rewriteMovedNotes`)
- `note/Unpinned/supabase.REMOTE_FOLDER_DELETED` — `lib/core/services/sync_service.dart` (`_removeRemoteFolder`, `_rewriteNotesMovedFrom`)
- `note/In trash/supabase.REMOTE_FOLDER_DELETED` — `lib/core/services/sync_service.dart` (`_removeRemoteFolder`, `_rewriteNotesMovedFrom`)

## Feedback

Drift h4kt62zv resolved by Proposal 4bde0hn9
