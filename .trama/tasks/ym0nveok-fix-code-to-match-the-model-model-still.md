---
column: done
technical: false
refs:
  - mobile-navigation/Folders/user.SELECT_TAG
drift: 8ns748h9
proposal: null
agent: false
created: 2026-10-12T14:20:57.111Z
finished: 2026-10-12T14:22:07.793Z
---
# Fix code to match the Model: Model still describes double tag application in Folders

## What happens

Su mobile, toccando un tag nella schermata Cartelle, l'app mostra le note con quel tag e il filtro resta attivo, applicato una sola volta. Il tocco non annulla il filtro, anche se quel tag era già l'unico selezionato.

## What should happen

Il Model descrive ancora due passaggi di seguito sullo stesso tag, che annullano il filtro. Questo contraddice il Requirement di organizzazione, che vuole la vista Tutte le note filtrata da quel tag, e la decisione del Drift risolto (pztqr8es, Task 1yah5xzy), che sceglie un solo passaggio. Il Model non è stato riscritto dopo quella decisione, quindi non può essere seguito così com'è.

## Chosen option

**Rewrite the Model to a single application**

Riscrivere nel Model di Cartelle la transizione verso la lista e le transizioni di note-browser che descrivono il doppio passaggio, lasciando un solo passaggio: il tocco su un tag mostra le note con quel tag. Il codice resta invariato, perché già si comporta così. Costo: una Proposal che aggiorna il Model di navigazione e di note-browser.

## Where in the code

Schermata Cartelle su mobile: il tocco su un tag; stato dei tag selezionati.
