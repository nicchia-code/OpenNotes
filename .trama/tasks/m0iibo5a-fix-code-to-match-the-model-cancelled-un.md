---
column: done
technical: false
refs:
  - mobile-navigation/Notes list/user.DUPLICATE_NOTE
drift: wet88tr4
proposal: null
agent: false
created: 2026-10-12T07:38:53.732Z
finished: 2026-10-12T07:44:36.590Z
---
# Fix code to match the Model: Cancelled unlock on duplicate opens another note

## What happens

Dalla lista, se l'utente annulla lo sblocco richiesto per duplicare una nota protetta, non viene aperto l'originale: si apre la nota che era selezionata prima, che spesso è un'altra nota, oppure non si apre nulla.

## What should happen

Dal menu della pressione prolungata, Duplica apre la copia appena creata; se lo sblocco della nota protetta viene annullato, si apre l'originale.

## Chosen option

**Aprire la nota su cui è stato aperto il menu**

La lista ricorda la nota toccata a lungo e la apre sia dopo la copia sia dopo l'annullamento dello sblocco. Il caso normale non cambia; il costo è un dato in più passato al menu. Coerente con il Model senza cambiarlo.

## Where in the code

lib/ui/mobile/mobile_notes_list_screen.dart (_showNoteContextMenu); lib/ui/notes_list/note_actions.dart (showMobile)
