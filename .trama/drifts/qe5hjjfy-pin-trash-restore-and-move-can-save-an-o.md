---
status: resolved
resolution: fix-code
refs:
  - note/Active
proposal: null
task: 4vn00ef8
origin: null
critical: false
option: 1
note: null
resolvedBy: 2di39ebu
created: 2026-10-13T12:25:40.160Z
---
# Pin, trash, restore and move can save an older text over a newer one still being written

## What happens

Fissare, spostare nel cestino, ripristinare o spostare in un'altra cartella una nota con una modifica al testo ancora in attesa o in scrittura riscrive la nota partendo dalla versione salvata, senza consegnare né scrivere prima il testo appena digitato. Se l'azione legge la versione vecchia mentre il testo si sta salvando, il database e il file possono restare con il testo precedente. Duplicare, condividere ed esportare invece consegnano prima il testo in attesa. È lo stesso meccanismo del Drift sul lucchetto wt2f9ej0, che però riguarda solo il lucchetto.

## What should happen

Il Model delle note dice che fissare, spostare nel cestino, ripristinare e spostare aggiornano la data di modifica e salvano la nota. Il Requirement dice che le modifiche al contenuto vengono salvate dopo 400 ms e che la scrittura in attesa parte subito quando l'app va in secondo piano. Nessuno dei due ammette che un cambio di stato riporti indietro un testo appena scritto. Non si può seguire perché queste azioni leggono la nota dalla versione salvata prima di riscriverla, senza consegnare il testo in attesa.

## Fix options

### Consegnare e scrivere il testo in attesa prima di ogni cambio di stato

Fissa, cestino, ripristino e spostamento consegnano e scrivono il testo in attesa prima di leggere la nota, come già fanno duplicare e spostare dal menu; il cambio di stato viene poi applicato alla versione più recente. Costo: una scrittura in più quando c'è un testo in attesa; per l'utente non cambia nulla.

### Attendere il salvataggio in corso prima di cambiare stato

Ogni cambio di stato aspetta che il salvataggio del testo in corso finisca, poi legge la nota e la scrive con il nuovo stato. Il testo digitato negli ultimi istanti resta in attesa e viene salvato dopo. Costo: l'azione può attendere una scrittura in corso, e la versione più recente può comparire nel file con qualche istante di ritardo.

## Where in the code

lib/core/state/notes_provider.dart (togglePin, moveToTrash, restoreFromTrash, moveNoteToFolder, flushPendingContent); lib/ui/notes_list/note_actions.dart; lib/ui/shell/adaptive_app_shell.dart; lib/ui/mobile/mobile_notes_list_screen.dart
