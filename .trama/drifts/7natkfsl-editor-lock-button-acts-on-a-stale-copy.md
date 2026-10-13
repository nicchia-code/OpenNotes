---
status: resolved
resolution: dismissed
refs:
  - mobile-navigation/Editor from list
proposal: null
task: null
origin: null
previous: u2qtxr20
critical: true
option: null
note: null
created: 2026-10-13T05:46:09.537Z
---
# Editor lock button acts on a stale copy after the note leaves the list

## What happens

Dopo che la nota è uscita dalla selezione corrente, per esempio spostata in un'altra cartella, il pulsante di protezione dell'editor agisce ancora sulla versione mostrata prima dell'uscita. Il primo tocco mette il lucchetto, ma l'icona resta aperta; il tocco successivo **toglie il lucchetto senza chiedere il PIN**, anche se il PIN principale è già impostato.

## What should happen

Togliere il lucchetto richiede sempre il PIN principale corretto, anche quando la nota è già sbloccata per la sessione (note-access, `user.REMOVE_NOTE_LOCK`). L'editor mostra l'ultima versione ricevuta, ma il pulsante deve agire sulla stessa versione che lo stato salvato della nota dice: spostare la nota non deve cambiare ciò che il pulsante fa. Questo caso è già stato risolto una volta (u2qtxr20) e la correzione è tornata.

## Fix options

### Il pulsante legge la nota dai dati locali

Al tocco del lucchetto l'editor legge la nota salvata per identificatore e decide da quella se chiedere il PIN per togliere il lucchetto o mettere il lucchetto. Corretto anche per una nota uscita dalla lista, e l'icona si aggiorna dopo il salvataggio. Costa una lettura locale asincrona prima della richiesta del PIN.

### L'editor tiene aggiornata la protezione

Ad ogni cambiamento dei dati l'editor rilegge dai dati locali la nota aperta, anche se è uscita dalla selezione, e aggiorna solo cartella, cestino, fissaggio e protezione, lasciando il contenuto com'è. Il lucchetto e la sua icona seguono così lo stato salvato. Costa una lettura per ogni cambiamento mentre l'editor è aperto.

## Where in the code

lib/ui/mobile/mobile_note_editor_screen.dart: _onLock usa _lastKnownNote, che non si aggiorna quando la nota esce dalla lista; lib/core/state/notes_provider.dart: toggleLock inverte lo stato salvato senza confrontarlo con quello mostrato.
