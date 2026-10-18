---
column: done
technical: false
refs:
  - note-selection/Note selected/user.CREATE_NOTE
drift: e4lewslf
proposal: null
agent: false
created: 2026-10-18T16:59:40.145Z
finished: 2026-10-18T17:30:16.045Z
---
# Fix code to match the Model: Nota creata in una vista di cartella eliminata da un altro dispositivo non viene selezionata

## What happens

Quando una cartella viene eliminata da un altro dispositivo, la vista resta su quella cartella, ora inesistente, e l'elenco è vuoto. Se da quella vista si crea una nota, createNote la salva in Note e la imposta come selezionata, ma dopo il ricaricamento l'elenco della vista non la contiene: la selezione viene azzerata e nessuna nota resta aperta nell'editor del desktop.

## What should happen

Il Machine note-selection dice che la creazione seleziona la nuova nota e che la nota selezionata appartiene sempre alla vista corrente. Oggi la nota creata non è né nella vista né selezionata.

## Chosen option

**Passare a Note alla creazione**

Se la cartella della vista non esiste più, la creazione apre la vista Note e seleziona la nuova nota. Costo: un controllo in più in createNote e nel navigatore.

## Where in the code

lib/core/state/notes_provider.dart: createNote (righe 296-349, targetFolderId e _isSelectedFolderGone, _selectedNoteId = newNote.id, poi refreshNotes); refreshNotes (righe 201-213, la selezione cade su first o null); lib/core/services/sync_service.dart: _removeRemoteFolder (riga 714) non reimposta la vista di NotesProvider.
