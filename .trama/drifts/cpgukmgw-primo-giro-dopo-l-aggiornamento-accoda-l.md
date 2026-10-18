---
status: resolved
resolution: proposal
refs:
  - pending-change
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: reg9oh8m
created: 2026-10-18T16:41:19.235Z
---
# Primo giro dopo l'aggiornamento accoda le copie locali, il Model non lo prevede

## What happens

Nel primo giro dopo l'aggiornamento, una nota o una cartella locale già sincronizzata senza revisione nota, con campi diversi dal cloud e più recente della riga del cloud, viene salvata con la revisione del cloud e accodata come salvataggio (*upsert*). Il cambiamento nasce così senza un salvataggio fatto dall'utente sul dispositivo.

## What should happen

Il Requirement sync-run (Primo giro dopo l'aggiornamento) dice che la copia locale vincente entra in coda come salvataggio basato sulla revisione del cloud, quindi il comportamento è previsto. Il Model di pending-change, invece, elenca come nascite solo i salvataggi e le eliminazioni fatti sul dispositivo e la creazione, rinomina o eliminazione di cartelle, e non cita questo percorso.

## Fix options

### Aggiornare il Model

Aggiungere alla descrizione di pending-change la nascita di un salvataggio dal primo giro dopo l'aggiornamento, quando la copia locale vince sul cloud. Il codice e il Requirement restano invariati. Il Model diventa completo rispetto al comportamento reale e il Requirement sync-run resta la fonte della regola.

### Non accodare, inviare dal primo giro

Eliminare l'accodamento in _adoptRevisions e inviare la copia locale vincente direttamente in quel giro con push_note/push_folder sulla revisione letta. Questo rompe il Requirement sync-run, che chiede l'ingresso in coda come salvataggio, e richiede un passaggio ulteriore di approvazione.

## Where in the code

lib/core/services/sync_service.dart: _adoptRevisions (notes e folders), con queueSyncAction seguito da _start(full: false)
