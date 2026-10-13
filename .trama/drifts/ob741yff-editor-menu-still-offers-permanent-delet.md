---
status: resolved
resolution: dismissed
refs:
  - mobile-navigation/Editing from list/user.DELETE_NOTE_PERMANENTLY
proposal: null
task: null
origin: null
previous: fso8f4q0
critical: false
option: null
note: null
created: 2026-10-13T05:46:02.042Z
---
# Editor menu still offers permanent deletion after restore from trash

## What happens

Un editor aperto dal cestino resta sullo schermo quando la nota viene ripristinata dal suo stesso menu. Da quel momento il menu continua a proporre i comandi del cestino: **Elimina definitivamente** e **Ripristina nota**. La condivisione resta nascosta finché l'editor non viene riaperto. Scegliendo Elimina definitivamente e confermando, la nota attiva viene cancellata dal dispositivo e dal cloud.

## What should happen

**Elimina definitivamente** vale solo per una nota nel cestino, dal menu azioni nel cestino (Editing from list, `user.DELETE_NOTE_PERMANENTLY`). Una nota fuori dal cestino può solo essere spostata nel cestino. Ripristinare dal menu lascia l'editor aperto con l'ultima versione ricevuta, ma il menu deve riflettere lo stato attuale della nota.

## Fix options

### Il menu segue lo stato attuale della nota

All'apertura del menu l'editor legge la nota dai dati locali e propone solo i comandi e la condivisione che valgono per il suo stato attuale. Il contenuto resta l'ultima versione mostrata. Coerente con il Model senza cambiarlo; costa una lettura locale ogni volta che si apre il menu.

### L'editor tiene aggiornato lo stato della nota

Ad ogni cambiamento dei dati l'editor rilegge dai dati locali la nota aperta, anche se è uscita dalla selezione, e ne aggiorna solo lo stato (cartella, cestino, fissaggio, protezione), lasciando il contenuto com'è. Menu, condivisione e lucchetto seguono così il salvato. Costa una lettura per ogni cambiamento mentre l'editor è aperto.

## Where in the code

lib/ui/mobile/mobile_note_editor_screen.dart: _showMoreMenu e _lastKnownNote, che non si aggiorna quando la nota esce dalla lista; lib/ui/notes_list/note_action_menu.dart: actionsFor sceglie i comandi dal flag di cestino della versione passata. Già risolto con fso8f4q0 / Task o1fqpkva, ma il codice attuale non legge lo stato corrente.
