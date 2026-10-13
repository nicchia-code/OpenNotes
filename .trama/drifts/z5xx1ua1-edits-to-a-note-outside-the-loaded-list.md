---
status: resolved
resolution: fix-code
refs:
  - note-content-save/Idle
proposal: null
task: kjenovni
origin: null
previous: i9ndys4i
critical: false
option: 1
note: null
resolvedBy: q11nyyet
created: 2026-10-13T06:35:37.161Z
---
# Edits to a note outside the loaded list are saved again

## What happens

Quando arriva una modifica di testo per una nota che non è più nell'elenco caricato (per esempio spostata nel cestino, o sparita dalla sincronizzazione mentre era aperta), il sistema la prende in carico lo stesso: la modifica entra in attesa e viene scritta nel database e nel file della nota. Viene saltato solo l'aggiornamento in memoria dell'elenco.

## What should happen

Il Modello dice che la modifica viene accettata solo se la nota è tra quelle dell'elenco caricato, sia durante l'attesa sia alla consegna per uscita dal primo piano. Per una nota fuori dall'elenco non c'è alcuna transizione: la modifica non entra in attesa e non viene scritta.

## Fix options

### Ripristinare il vincolo nel salvataggio

Il salvataggio ignora le modifiche di note che non sono nell'elenco caricato, come dice il Modello: non entrano in attesa e non vengono scritte. **Costo:** il testo digitato negli ultimi istanti prima che la nota esca dall'elenco va perso senza avviso. Era la scelta del Drift i9ndys4i, risolto, ma il controllo oggi non c'è più.

### Fermare la consegna nell'editor

L'editor non consegna la modifica quando la sua nota non è più nell'elenco caricato, così il salvataggio non la riceve. Il risultato visibile è lo stesso, ma la regola sta nell'editor, che oggi non conosce l'elenco caricato: serve una dipendenza nuova. **Costo:** il testo resta visibile nell'editor fino alla chiusura, ma non viene salvato.

## Where in the code

lib/core/state/notes_provider.dart (updateNoteContent)
