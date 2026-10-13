---
column: done
technical: false
refs:
  - sync-run/Pulling
  - requirements/rules#sync-run
drift: null
proposal: null
agent: false
created: 2026-10-13T10:42:05.657Z
finished: 2026-10-13T10:52:51.247Z
---
# Fix code to match the Model: Attachments of a cloud note are downloaded although its queued delete keeps the note deleted

## What happens

Quando la versione di una nota del cloud arriva mentre un'eliminazione di quella nota è in coda e l'eliminazione resta valida, le immagini e i disegni della nota del cloud vengono scaricati comunque, anche se la versione del cloud non sostituisce la copia locale.

## What should happen

Gli allegati si scaricano solo quando la versione del cloud sostituisce quella locale. Se l'eliminazione in coda resta valida, la nota non viene sostituita e nessun allegato viene scaricato.
