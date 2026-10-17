---
status: resolved
resolution: proposal
refs:
  - note-content-save/Waiting
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: hp4kwvga
created: 2026-10-17T12:12:04.760Z
---
# Note commands write the waiting content at once, the Model has no such exit

## What happens

Se una nota viene fissata, protetta o sbloccata, messa nel cestino, ripristinata o spostata in un'altra cartella mentre una sua modifica aspetta ancora di essere scritta, il sistema scrive subito quella modifica, senza aspettare la pausa di 400 ms, e solo dopo esegue il comando. Per chi usa l'app, il risultato è la stessa nota salvata prima del comando, ma l'attesa finisce prima del tempo previsto.

## What should happen

Il Model dice che la versione in attesa passa a inattiva solo allo scadere dell'attesa o quando l'app lascia il primo piano: le uscite dall'attesa sono soltanto queste. Il Requirement fissa la pausa di 400 ms e la scrittura immediata solo all'uscita dall'app, e non dice nulla dei comandi sulla nota.

## Fix options

### Aggiungere le uscite dei comandi al Model

Il Model aggiunge, per ogni comando sulla nota, l'uscita dall'attesa verso inattiva: la versione in attesa viene scritta subito, prima del comando. Il comportamento del codice resta com'è, perché è la scelta già presa per non sovrascrivere il testo con una versione vecchia. Costo: alcune voci in più nel Model, da aggiornare quando si aggiunge un comando.

### Lasciare che i comandi aspettino la scrittura

I comandi non consegnano il testo in attesa: la scrittura resta alla sua scadenza, e il comando agisce sulla nota com'è salvata, perché la scrittura riporta solo contenuto, titolo, tag, anteprima e data. Il Model resta com'è. Costo: l'ultimo testo digitato arriva al database e al file fino a 400 ms dopo il comando, e il comando può attendere una scrittura già in corso.

## Where in the code

lib/core/state/notes_provider.dart (_settleContent e i comandi togglePin, toggleLock, moveToTrash, restoreFromTrash, moveNoteToFolder)
