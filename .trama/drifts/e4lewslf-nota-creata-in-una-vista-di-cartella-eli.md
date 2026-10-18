---
status: resolved
resolution: fix-code
refs:
  - note-selection/Note selected/user.CREATE_NOTE
proposal: null
task: 6ry3hia6
origin: null
previous: 41xbhham
critical: false
option: 3
note: null
resolvedBy: igfpa73s
created: 2026-10-18T16:39:56.480Z
---
# Nota creata in una vista di cartella eliminata da un altro dispositivo non viene selezionata

## What happens

Quando una cartella viene eliminata da un altro dispositivo, la vista resta su quella cartella, ora inesistente, e l'elenco è vuoto. Se da quella vista si crea una nota, createNote la salva in Note e la imposta come selezionata, ma dopo il ricaricamento l'elenco della vista non la contiene: la selezione viene azzerata e nessuna nota resta aperta nell'editor del desktop.

## What should happen

Il Machine note-selection dice che la creazione seleziona la nuova nota e che la nota selezionata appartiene sempre alla vista corrente. Oggi la nota creata non è né nella vista né selezionata.

## Fix options

### Spostare la vista su Tutte le note

Quando la cartella viene eliminata da un altro dispositivo, la vista passa a Tutte le note, come già accade per l'eliminazione locale. La nota creata è nella vista e resta selezionata. Costo: la vista cambia sotto l'utente, e l'eliminazione remota deve reimpostare la selezione.

### Selezionare comunque la nota creata

La nota creata resta selezionata anche se non compare nella vista corrente, come per la nota aperta da un'altra vista. Costo: viene violata la regola che la selezione appartiene alla vista, e il Model di note-selection va cambiato.

### Passare a Note alla creazione

Se la cartella della vista non esiste più, la creazione apre la vista Note e seleziona la nuova nota. Costo: un controllo in più in createNote e nel navigatore.

## Where in the code

lib/core/state/notes_provider.dart: createNote (righe 296-349, targetFolderId e _isSelectedFolderGone, _selectedNoteId = newNote.id, poi refreshNotes); refreshNotes (righe 201-213, la selezione cade su first o null); lib/core/services/sync_service.dart: _removeRemoteFolder (riga 714) non reimposta la vista di NotesProvider.
