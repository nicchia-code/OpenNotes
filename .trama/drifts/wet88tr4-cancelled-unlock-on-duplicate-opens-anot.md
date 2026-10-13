---
status: resolved
resolution: fix-code
refs:
  - mobile-navigation/Notes list/user.DUPLICATE_NOTE
proposal: null
task: m0iibo5a
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:26:25.568Z
---
# Cancelled unlock on duplicate opens another note

## What happens

Dalla lista, se l'utente annulla lo sblocco richiesto per duplicare una nota protetta, non viene aperto l'originale: si apre la nota che era selezionata prima, che spesso è un'altra nota, oppure non si apre nulla.

## What should happen

Dal menu della pressione prolungata, Duplica apre la copia appena creata; se lo sblocco della nota protetta viene annullato, si apre l'originale.

## Fix options

### Aprire la nota su cui è stato aperto il menu

La lista ricorda la nota toccata a lungo e la apre sia dopo la copia sia dopo l'annullamento dello sblocco. Il caso normale non cambia; il costo è un dato in più passato al menu. Coerente con il Model senza cambiarlo.

### Non aprire nulla se lo sblocco è annullato

Dopo l'annullamento la lista resta com'è, senza editor. È il comportamento più semplice da mantenere, ma il Model va cambiato: la transizione verso l'editor non avviene più in quel caso. Nessun rischio di aprire la nota sbagliata.

## Where in the code

lib/ui/mobile/mobile_notes_list_screen.dart (_showNoteContextMenu); lib/ui/notes_list/note_actions.dart (showMobile)
