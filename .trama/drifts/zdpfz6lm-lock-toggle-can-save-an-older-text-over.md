---
status: resolved
resolution: fix-code
refs:
  - note-access/Protected
proposal: null
task: gddq160l
origin: null
critical: false
option: 1
note: null
resolvedBy: 37m9hzhb
created: 2026-10-13T05:23:18.151Z
---
# Lock toggle can save an older text over a newer one still being written

## What happens

Quando si mette o si toglie il lucchetto, l'app legge la nota dal database e la riscrive con il nuovo stato, senza prima consegnare né scrivere il testo appena digitato, a differenza di duplicare, spostare, condividere ed esportare. Se una scrittura del testo finisce nello stesso momento, la versione del lucchetto può riportare nel database e nel file del vault un testo più vecchio, e il file può restare con lo stato del lucchetto precedente.

## What should happen

Il Requirement dell'accesso dice che mettere o togliere il lucchetto aggiorna la data e salva la nota nel database locale, nel vault e nella coda di sincronizzazione: vault e database devono dire la stessa cosa. Il Requirement del salvataggio del testo dice che la scrittura del testo lascia intatti fissaggio e protezione cambiati durante l'attesa; il cambio del lucchetto non deve a sua volta riportare indietro il testo.

## Fix options

### Deliver and write the waiting text before changing the lock (recommended)

Il cambio del lucchetto consegna il testo in attesa e lo scrive prima di leggere la nota, come fanno duplicare e spostare. Costo: una scrittura in più quando si cambia il lucchetto con un testo in attesa; nessun cambiamento per l'utente.

### Re-read the note after the vault write

Il cambio del lucchetto rilegge la nota dal database dopo la scrittura del file e salva il testo più recente, come già fa il salvataggio del testo. Costo: resta una piccola finestra in cui il file può avere il vecchio stato del lucchetto, perché il file è scritto prima della rilettura.

## Where in the code

lib/core/state/notes_provider.dart (toggleLock, flushPendingContent); lib/ui/mobile/mobile_note_editor_screen.dart (_onLock); lib/ui/notes_list/note_actions.dart (NoteMenuAction.lock)
