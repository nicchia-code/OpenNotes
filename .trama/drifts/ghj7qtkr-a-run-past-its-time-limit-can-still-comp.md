---
status: resolved
resolution: fix-code
refs:
  - sync-run/Running
  - requirements/rules#sync-run
proposal: null
task: 2xsxl2sk
origin: null
critical: false
option: 1
note: null
resolvedBy: tqf85in9
created: 2026-10-17T17:21:36.760Z
---
# A run past its time limit can still complete

## What happens

Se il giro supera il suo tempo massimo mentre scarica o carica gli allegati, il limite non lo fa fallire: ogni allegato la cui richiesta scade viene solo annotato, e il giro risulta completato. Così l'ora dell'ultima sincronizzazione si aggiorna e il nuovo tentativo non parte. Il limite viene controllato solo quando il giro fa la richiesta successiva al cloud.

## What should happen

Secondo il Model, lo scadere del tempo massimo di un giro fa fallire il giro con la categoria **tempo scaduto**, in qualsiasi passo, e il giro passa in attesa di un nuovo tentativo. Fa eccezione solo l'allegato che non si carica o non si scarica: questo non fa fallire il giro, ma il tempo massimo del giro sì.

## Fix options

### Fail the run when its limit passes during attachments

Quando il tempo del giro è finito durante gli allegati, il giro fallisce con tempo scaduto e passa in attesa di un nuovo tentativo. Un allegato che fallisce per altri motivi resta annotato, come oggi. Costo: un allegato lento vicino al limite fa fallire il giro, e il nuovo tentativo parte prima che l'allegato sia pronto.

### Check the limit after the attachment steps

Gli allegati vengono provati fino in fondo, poi il giro controlla il tempo massimo: se è stato superato fallisce con tempo scaduto, altrimenti completa come oggi. Costo: il giro può superare il limite di qualche secondo mentre finisce gli allegati, e i caricamenti già partiti si concludono prima del fallimento.

## Where in the code

lib/core/services/sync_service.dart: `_cloud` risponde con `TimeoutException` quando il tempo del giro è finito, ma `_uploadMissingAttachments` e `_downloadAttachmentsOfAllNotes` annotano ogni errore senza distinguere il tempo del giro; `_performRun` quindi arriva alla fine e `_runOnce` salva il risultato come completato.
