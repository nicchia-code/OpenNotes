---
status: resolved
resolution: dismissed
refs:
  - note-editor/Open/note-selection.SELECTED_NOTE_CHANGED
  - note-editor/Protected/note-selection.SELECTED_NOTE_CHANGED
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: null
created: 2026-10-12T18:44:23.078Z
---
# Note switch saves the waiting edit to the previous note, the Model says it is discarded

## What happens

Quando la nota selezionata cambia mentre l'editor ha una modifica di testo non ancora consegnata (la pausa di 300 ms non è scaduta), l'editor consegna quella modifica alla nota che la conteneva, e solo dopo carica la nuova nota. Succede anche quando la nuova nota è protetta: la modifica viene comunque scritta nella nota precedente.

## What should happen

Il Model dice che, quando la nota selezionata cambia e va in Open o in Protected, la modifica in attesa viene **scartata senza essere salvata**, e il documento della nuova nota viene caricato. Lo stesso vale per la selezione di nessuna nota.

## Fix options

### Salvare la modifica nella sua nota e correggere il Model

L'editor consegna la modifica in attesa alla nota a cui appartiene, come oggi, e il Model viene aggiornato per dirlo nei passaggi Open e Protected. **Effetto:** il testo digitato poco prima del cambio di nota non va perso, come accade già con copia, condivisione, esportazione e chiusura dell'app, che consegnano ciò che è sullo schermo. **Costo:** correggere tre transizioni del Model e accettare una scrittura della nota precedente in un momento che il Model non descrive oggi.

### Scartare la modifica come dice il Model

Quando la nota selezionata cambia, la modifica in attesa viene scartata senza consegnarla, come descrive il Model. **Effetto:** il comportamento segue il Model, ma i caratteri digitati nell'ultimo mezzo secondo prima del cambio di nota vanno persi, mentre copia, condivisione ed esportazione li salvano. **Costo:** rimuovere la consegna nel cambio di nota; il codice diventa più semplice, ma la perdita di testo è visibile all'utente.

## Where in the code

Desktop: il ramo di cambio nota in didUpdateWidget di lib/ui/editor/notion_document_editor.dart, alimentato dalla colonna dell'editor in lib/ui/shell/adaptive_app_shell.dart. Il mobile crea una nuova schermata per ogni nota e non passa da questo ramo.
