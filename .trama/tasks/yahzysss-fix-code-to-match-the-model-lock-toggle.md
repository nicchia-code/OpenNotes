---
column: done
technical: false
refs:
  - note
drift: 94f8qgwb
proposal: null
agent: false
created: 2026-10-17T10:01:51.028Z
finished: 2026-10-17T10:03:45.942Z
---
# Fix code to match the Model: Lock toggle can save an older text over a newer one still being written again

## What happens

Mettere o togliere il lucchetto legge la nota dal database e la riscrive con il nuovo stato senza prima consegnare né scrivere il testo appena digitato. Se una scrittura del testo è in attesa o in corso, il lucchetto riporta nel database e nel file del vault una versione più vecchia del testo. Fissare, spostare nel cestino, ripristinare e spostare già consegnano il testo prima di leggere la nota; il lucchetto no.

## What should happen

Il Model dice che mettere o togliere il lucchetto aggiorna la data di modifica e salva la nota. Il Requirement dice che la scrittura del testo lascia intatti fissaggio e protezione cambiati durante l'attesa e che il cambio del lucchetto non deve riportare indietro il testo; vault e database devono dire la stessa cosa. Questo Drift segue zdpfz6lm, già risolto, che è tornato nel codice.

## Chosen option

**Consegnare e scrivere il testo in attesa prima del lucchetto (consigliata)**

Il cambio del lucchetto consegna il testo in attesa e lo scrive prima di leggere la nota, come già fanno fissare, spostare nel cestino, ripristinare e spostare. Costo: una scrittura in più quando si cambia il lucchetto con un testo in attesa; nessun cambiamento per l'utente.

## Where in the code

lib/core/state/notes_provider.dart (toggleLock, righe 471-485, senza _settleContent; confronta togglePin e moveToTrash); lib/ui/notes_list/note_actions.dart; lib/ui/mobile/mobile_note_editor_screen.dart (_onLock)
