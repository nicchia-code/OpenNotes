---
status: resolved
resolution: dismissed
refs:
  - note-content-save/Waiting
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: null
created: 2026-10-12T18:41:27.053Z
---
# Model says a waiting save of another note is dropped, code writes it at once

## What happens

Quando l'utente modifica una nota mentre la modifica di un'altra nota è ancora in attesa, il sistema scrive subito la modifica in attesa della prima nota, poi fa partire l'attesa per la nuova. Nessuna modifica si perde: la scrittura resta un solo timer condiviso da tutte le note.

## What should happen

Il Model dice che, quando la versione in attesa appartiene a un'altra nota, viene sostituita e **quella nota non viene più scritta**. Il Model descrive quindi la perdita della modifica. Il developer ha però già scelto, nel Task ojsj17eo, di scrivere subito la modifica in attesa, e il codice lo fa: il Model non è stato aggiornato.

## Fix options

### Aggiornare il Model: la modifica in attesa viene scritta subito

Il Model dice che, quando cambia nota, la modifica in attesa della precedente viene scritta subito e poi parte l'attesa per la nuova, con un solo timer condiviso. Il comportamento del codice resta com'è. Costo: una scrittura in più quando si passa rapidamente da una nota all'altra; la regola va scritta nel Model.

### Tornare a scartare la modifica in attesa

Il codice torna a sostituire la modifica in attesa della nota precedente senza scriverla, come dice il Model. Costo: una modifica appena fatta va persa se si passa a un'altra nota entro 400 ms, cioè proprio il caso che la scelta già presa voleva evitare.

## Where in the code

lib/core/state/notes_provider.dart (updateNoteContent, flushPendingContent)
