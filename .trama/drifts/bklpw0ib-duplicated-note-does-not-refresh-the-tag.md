---
status: resolved
resolution: fix-code
refs:
  - note-browser/Browsing
proposal: null
task: 0ku1mii0
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:34:45.607Z
---
# Duplicated note does not refresh the tag list

## What happens

Quando duplichi una nota, la copia compare nell'elenco e i conteggi delle cartelle si aggiornano, ma l'elenco dei tag resta quello di prima. I tag della copia non aumentano il numero di note finché non si crea o si salva un'altra nota.

## What should happen

Il Model dice che l'elenco dei tag si aggiorna alla creazione di una nota. La copia ha gli stessi tag dell'originale, quindi il loro conteggio deve salire subito.

## Fix options

### Rileggere i tag dopo la duplicazione

Dopo la copia l'elenco dei tag viene riletto, come già avviene alla creazione di una nota. Una riga in più e nessun effetto sul resto. Costo: una lettura in più del database a ogni duplicazione.

### Ricalcolare i tag a ogni ricarica dell'elenco

L'elenco dei tag viene riletto ogni volta che viene riletto quello delle note, anche dopo il cestino, il ripristino o lo spostamento di una nota. I conteggi restano sempre allineati. Costo: il calcolo scorre tutte le note non nel cestino a ogni modifica, e il Model va riscritto per dire questo.

## Where in the code

lib/core/state/notes_provider.dart, duplicateNote: rilegge note e conteggi ma non i tag.
