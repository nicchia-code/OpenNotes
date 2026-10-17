---
column: done
technical: false
refs:
  - note-editor/Open/note-selection.SELECTED_NOTE_CHANGED
drift: jkugm6i1
proposal: null
agent: false
created: 2026-10-17T11:45:53.548Z
finished: 2026-10-17T12:03:49.683Z
---
# Fix code to match the Model: Note switch saves the waiting edit to the previous note, the Model says it is discarded

## What happens

Quando la nota selezionata cambia mentre l'editor ha una modifica di testo non ancora consegnata (la pausa di 300 ms non è scaduta), l'editor consegna quella modifica alla nota che la conteneva, e solo dopo carica la nuova nota. Succede anche quando la nuova nota è protetta: la modifica viene comunque scritta nella nota precedente. Sul desktop, dove un solo editor è riutilizzato fra le note.

## What should happen

Il Model dice che, quando la nota selezionata cambia e va in Open o in Protected, la modifica in attesa viene scartata senza essere salvata, e il documento della nuova nota viene caricato. Lo stesso vale quando non è più selezionata nessuna nota.

## Chosen option

**Discard the waiting edit in the editor on note switch**

Il cambio di nota non consegna più la modifica in attesa: il documento viene sostituito e il testo digitato nell'ultimo mezzo secondo prima del cambio va perso, come dice il Model. Copia, condivisione ed esportazione restano invariate, perché consegnano lo schermo prima di agire. Costo: caratteri recenti persi senza avviso quando si cambia nota in fretta.

## Where in the code

lib/ui/editor/notion_document_editor.dart: didUpdateWidget, ramo del cambio di nota (righe 222-227); lib/ui/shell/adaptive_app_shell.dart: colonna dell'editor desktop
