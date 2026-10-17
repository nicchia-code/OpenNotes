---
status: resolved
resolution: fix-code
refs:
  - note-selection/Note selected
proposal: null
task: 15lkdbop
origin: null
critical: false
option: 1
note: null
resolvedBy: uo2rau9q
created: 2026-10-17T12:43:34.368Z
---
# Trash-view delete moves the selection to a neighbour although the note stays listed

## What happens

Nella vista Cestino, il comando Elimina nota della barra desktop rinnova la data di eliminazione della nota selezionata, che però resta nell'elenco del cestino. Dopo la ricarica il sistema seleziona la nota successiva dell'elenco, o la precedente se era l'ultima: la selezione salta via dalla nota su cui l'utente ha appena agito, anche se questa è ancora visibile e non è cambiata di vista.

## What should happen

Il Model note-selection dice che lo spostamento nel cestino seleziona la nota successiva o la precedente, senza distinguere il caso in cui la nota resta nell'elenco; e dice che, dopo una ricarica, la selezione resta com'è se la nota selezionata è ancora nell'elenco. Il Model note, per una nota già nel cestino, dice solo che la nota registra di nuovo la data di eliminazione, senza nulla sulla selezione. Le due regole di note-selection sono in conflitto per questo caso e il Model non stabilisce quale valga: non si può implementarle entrambe.

## Fix options

### Keep the selection on the renewed note

La selezione resta sulla nota rinnovata; la regola dello spostamento vale solo per le note che escono dalla vista. Costo: il Model note-selection va chiarito su questo punto con una decisione separata, e il codice deve distinguere i due casi.

### Keep the neighbour selection

Il comportamento attuale resta: la selezione passa alla nota vicina anche nel cestino. Costo: a ogni rinnovo l'editor mostra un'altra nota, e l'utente può agire su una nota diversa da quella che voleva.

### Renew the trash date through a separate operation

Il rinnovo passa da un'operazione dedicata che aggiorna solo data di eliminazione e di modifica e non tocca la selezione; lo spostamento nel cestino resta com'è. Costo: una seconda via di scrittura da tenere allineata con quella dello spostamento, e la questione del Model resta aperta per lo spostamento fuori dal cestino.

## Where in the code

lib/core/state/notes_provider.dart (moveToTrash, refreshNotes); lib/ui/shell/adaptive_app_shell.dart (_onDelete); lib/ui/shell/mac_title_bar.dart (pulsante Elimina nota nella vista Cestino)
