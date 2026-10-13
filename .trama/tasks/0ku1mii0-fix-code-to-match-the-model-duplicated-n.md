---
column: done
technical: false
refs:
  - note-browser/Browsing
drift: bklpw0ib
proposal: null
agent: false
created: 2026-10-12T07:38:53.842Z
finished: 2026-10-12T07:46:12.270Z
---
# Fix code to match the Model: Duplicated note does not refresh the tag list

## What happens

Quando duplichi una nota, la copia compare nell'elenco e i conteggi delle cartelle si aggiornano, ma l'elenco dei tag resta quello di prima. I tag della copia non aumentano il numero di note finché non si crea o si salva un'altra nota.

## What should happen

Il Model dice che l'elenco dei tag si aggiorna alla creazione di una nota. La copia ha gli stessi tag dell'originale, quindi il loro conteggio deve salire subito.

## Chosen option

**Rileggere i tag dopo la duplicazione**

Dopo la copia l'elenco dei tag viene riletto, come già avviene alla creazione di una nota. Una riga in più e nessun effetto sul resto. Costo: una lettura in più del database a ogni duplicazione.

## Where in the code

lib/core/state/notes_provider.dart, duplicateNote: rilegge note e conteggi ma non i tag.
