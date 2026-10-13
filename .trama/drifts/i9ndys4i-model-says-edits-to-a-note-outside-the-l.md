---
status: resolved
resolution: fix-code
refs:
  - note-content-save/Waiting
proposal: null
task: kw7iplkf
origin: null
critical: false
option: 1
note: null
resolvedBy: 37m9hzhb
created: 2026-10-13T05:43:02.901Z
---
# Model says edits to a note outside the loaded list are ignored, the code saves them

## What happens

Quando arriva una modifica di testo per una nota che non è più nell'elenco caricato (per esempio spostata nel cestino, o fatta sparire dalla sincronizzazione mentre era aperta), il sistema la prende in carico lo stesso: la scrive nel database e nel file della nota dopo l'attesa, senza controllare che la nota sia ancora nell'elenco. Solo l'aggiornamento in memoria dell'elenco viene saltato.

## What should happen

Il Model dice che la modifica viene accettata solo se la nota è tra quelle dell'elenco caricato, sia dall'attesa sia dalla consegna per uscita dal primo piano. Per una nota fuori dall'elenco non c'è alcuna transizione: la modifica non entra in attesa e non viene scritta. Il vincolo non è più nel codice, e il Drift risolto c880tauf si basava ancora su di esso.

## Fix options

### Ripristinare il vincolo nel salvataggio

Il salvataggio del testo ignora le note che non sono nell'elenco caricato, come dice il Model: la modifica non viene messa in attesa né scritta. **Effetto:** il testo digitato negli ultimi istanti prima che la nota esca dall'elenco va perso senza avviso. **Costo:** poco, perché sul mobile l'editor si chiude già quando la nota esce dall'elenco; resta il caso della sincronizzazione e del cambio di nota sul desktop.

### Fermare la consegna nell'editor

L'editor non consegna il testo in attesa quando la sua nota non è più nell'elenco caricato, così il salvataggio non riceve la modifica. **Effetto:** stesso risultato visibile dell'altra strada, ma la regola sta nell'editor e il salvataggio accetta ogni nota che gli arriva. **Costo:** l'editor deve leggere l'elenco caricato, una dipendenza nuova che oggi non ha; il testo resta visibile nell'editor fino alla chiusura.

## Where in the code

lib/core/state/notes_provider.dart (updateNoteContent); lib/ui/editor/notion_document_editor.dart (_doSerializeAndSave)
