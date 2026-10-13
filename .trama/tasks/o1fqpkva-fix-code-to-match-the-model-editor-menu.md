---
column: done
technical: false
refs:
  - mobile-navigation/Editing from list/user.DELETE_NOTE_PERMANENTLY
drift: fso8f4q0
proposal: null
agent: false
created: 2026-10-12T08:09:28.389Z
finished: 2026-10-12T08:11:20.415Z
---
# Fix code to match the Model: Editor menu offers permanent deletion of a note restored from trash

## What happens

Un editor aperto dal cestino resta sullo schermo dopo che la nota è stata ripristinata o spostata in una cartella. Il suo menu azioni continua a proporre i comandi del cestino, tra cui **Elimina definitivamente**: scegliendolo e confermando, la nota attiva viene cancellata dal dispositivo e dal cloud, anche se non è più nel cestino.

## What should happen

Elimina definitivamente vale solo per una nota nel cestino, dal menu azioni nel cestino, e con la conferma (dopo il PIN se la nota è protetta). Una nota fuori dal cestino può solo essere spostata nel cestino. Il menu deve riflettere lo stato attuale della nota, mentre l'editor resta aperto con l'ultima versione ricevuta.

## Chosen option

**Il menu segue lo stato attuale della nota**

Quando si apre il menu, l'editor legge dai dati locali lo stato attuale della nota e propone solo i comandi che valgono per quello stato: fuori dal cestino, niente Elimina definitivamente. Il contenuto resta l'ultima versione mostrata. Coerente con il Model senza cambiarlo; costa una lettura in più all'apertura del menu.

## Where in the code

lib/ui/mobile/mobile_note_editor_screen.dart (_showMoreMenu passa l'ultima versione ricevuta a NoteActions); lib/ui/notes_list/note_action_menu.dart (actionsFor sceglie i comandi dal flag di cestino della versione passata)
