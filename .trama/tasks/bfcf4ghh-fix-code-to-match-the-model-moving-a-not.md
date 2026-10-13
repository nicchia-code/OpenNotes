---
column: done
technical: false
refs:
  - note-selection/Note selected
drift: null
proposal: null
agent: false
created: 2026-10-12T14:52:10.458Z
finished: 2026-10-12T16:29:02.522Z
---
# Fix code to match the Model: Moving a note to trash shows the first note before the neighbour

Nel codice `moveToTrash` (lib/core/state/notes_provider.dart) ricarica l'elenco con `refreshNotes()` e solo dopo, con un'altra attesa (`refreshTags()`), imposta la nota vicina. Se la nota spostata era quella selezionata, la ricarica seleziona prima la prima nota dell'elenco e notifica: per un istante l'editor può mostrare una nota diversa da quella attesa, e la selezione cambia due volte. Il Model prevede una sola variazione: dopo lo spostamento nel cestino è selezionata la nota che seguiva quella spostata, altrimenti la precedente, senza passare da altre note. Correggere facendo in modo che la nota vicina sia già la selezione quando l'elenco viene ricaricato, come fa già `duplicateNote` per la copia. Stesso schema da correggere in `createNote` quando non c'era una nota selezionata. Non cambiare le regole di scelta della nota vicina: si applicano solo il riferimento e l'ordine delle operazioni.
