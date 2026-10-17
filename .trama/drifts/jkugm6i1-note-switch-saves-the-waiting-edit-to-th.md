---
status: resolved
resolution: fix-code
refs:
  - note-editor/Open/note-selection.SELECTED_NOTE_CHANGED
proposal: null
task: yf0gv354
origin: null
critical: false
option: 1
note: null
resolvedBy: xqdml6er
created: 2026-10-17T11:34:28.284Z
---
# Note switch saves the waiting edit to the previous note, the Model says it is discarded

## What happens

Quando la nota selezionata cambia mentre l'editor ha una modifica di testo non ancora consegnata (la pausa di 300 ms non è scaduta), l'editor consegna quella modifica alla nota che la conteneva, e solo dopo carica la nuova nota. Succede anche quando la nuova nota è protetta: la modifica viene comunque scritta nella nota precedente. Sul desktop, dove un solo editor è riutilizzato fra le note.

## What should happen

Il Model dice che, quando la nota selezionata cambia e va in Open o in Protected, la modifica in attesa viene scartata senza essere salvata, e il documento della nuova nota viene caricato. Lo stesso vale quando non è più selezionata nessuna nota.

## Fix options

### Discard the waiting edit in the editor on note switch

Il cambio di nota non consegna più la modifica in attesa: il documento viene sostituito e il testo digitato nell'ultimo mezzo secondo prima del cambio va perso, come dice il Model. Copia, condivisione ed esportazione restano invariate, perché consegnano lo schermo prima di agire. Costo: caratteri recenti persi senza avviso quando si cambia nota in fretta.

### Clear the waiting write in the notes provider before reload

Il provider annulla la scrittura in attesa dell'editor prima che l'editor ricarichi la nuova nota, così il risultato per l'utente è lo stesso del Model ma la decisione sta fuori dal widget. Costo: il provider deve sapere che esiste una scrittura in attesa, quindi conosce il timer dell'editor e il ciclo di vita della consegna; il codice dell'editor cambia meno ma il confine fra provider ed editor si sposta.

## Where in the code

lib/ui/editor/notion_document_editor.dart: didUpdateWidget, ramo del cambio di nota (righe 222-227); lib/ui/shell/adaptive_app_shell.dart: colonna dell'editor desktop
