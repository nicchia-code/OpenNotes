---
column: done
technical: false
refs:
  - note-content-save/Idle
drift: z5xx1ua1
proposal: null
agent: false
created: 2026-10-13T13:13:35.544Z
finished: 2026-10-13T13:15:46.495Z
---
# Fix code to match the Model: Edits to a note outside the loaded list are saved again

## What happens

Quando arriva una modifica di testo per una nota che non è più nell'elenco caricato (per esempio spostata nel cestino, o sparita dalla sincronizzazione mentre era aperta), il sistema la prende in carico lo stesso: la modifica entra in attesa e viene scritta nel database e nel file della nota. Viene saltato solo l'aggiornamento in memoria dell'elenco.

## What should happen

Il Modello dice che la modifica viene accettata solo se la nota è tra quelle dell'elenco caricato, sia durante l'attesa sia alla consegna per uscita dal primo piano. Per una nota fuori dall'elenco non c'è alcuna transizione: la modifica non entra in attesa e non viene scritta.

## Chosen option

**Ripristinare il vincolo nel salvataggio**

Il salvataggio ignora le modifiche di note che non sono nell'elenco caricato, come dice il Modello: non entrano in attesa e non vengono scritte. **Costo:** il testo digitato negli ultimi istanti prima che la nota esca dall'elenco va perso senza avviso. Era la scelta del Drift i9ndys4i, risolto, ma il controllo oggi non c'è più.

## Where in the code

lib/core/state/notes_provider.dart (updateNoteContent)
