---
status: resolved
resolution: proposal
refs:
  - note-editor/Open
  - note-content-save/Waiting
proposal: null
task: null
origin: null
previous: c880tauf
critical: false
option: null
note: null
resolvedBy: gdnc8czu
created: 2026-10-17T17:57:58.318Z
---
# Edits to a note that left the list are lost while its editor stays open

## What happens

Sul telefono, quando la nota aperta viene spostata in un'altra cartella, ripristinata dal cestino o sparisce dai dati, l'editor resta aperto e mostra l'ultima versione. Il testo digitato da quel momento non viene salvato: non compare alcun avviso e la nota, nella sua nuova posizione, conserva il testo di prima.

## What should happen

Il Model dell'editor dice che la nota resta modificabile e che l'editor resta aperto dopo lo spostamento o il ripristino, senza dire che le modifiche vanno perse. Il Model del salvataggio dice invece che una modifica per una nota fuori dall'elenco caricato non viene accettata. Le due descrizioni non si accordano: l'utente vede un editor che accetta il testo e non lo salva.

## Where in the code

lib/core/state/notes_provider.dart (updateNoteContent); lib/ui/mobile/mobile_note_editor_screen.dart; lib/ui/notes_list/note_actions.dart (spostamento e ripristino non chiudono l'editor)
