---
column: done
technical: false
refs:
  - sync-run/Running
  - requirements/rules#sync-run
drift: ghj7qtkr
proposal: null
agent: false
created: 2026-10-17T17:39:37.241Z
finished: 2026-10-17T18:49:48.024Z
---
# Fix code to match the Model: A run past its time limit can still complete

## What happens

Se il giro supera il suo tempo massimo mentre scarica o carica gli allegati, il limite non lo fa fallire: ogni allegato la cui richiesta scade viene solo annotato, e il giro risulta completato. Così l'ora dell'ultima sincronizzazione si aggiorna e il nuovo tentativo non parte. Il limite viene controllato solo quando il giro fa la richiesta successiva al cloud.

## What should happen

Secondo il Model, lo scadere del tempo massimo di un giro fa fallire il giro con la categoria **tempo scaduto**, in qualsiasi passo, e il giro passa in attesa di un nuovo tentativo. Fa eccezione solo l'allegato che non si carica o non si scarica: questo non fa fallire il giro, ma il tempo massimo del giro sì.

## Chosen option

**Fail the run when its limit passes during attachments**

Quando il tempo del giro è finito durante gli allegati, il giro fallisce con tempo scaduto e passa in attesa di un nuovo tentativo. Un allegato che fallisce per altri motivi resta annotato, come oggi. Costo: un allegato lento vicino al limite fa fallire il giro, e il nuovo tentativo parte prima che l'allegato sia pronto.

## Where in the code

lib/core/services/sync_service.dart: `_cloud` risponde con `TimeoutException` quando il tempo del giro è finito, ma `_uploadMissingAttachments` e `_downloadAttachmentsOfAllNotes` annotano ogni errore senza distinguere il tempo del giro; `_performRun` quindi arriva alla fine e `_runOnce` salva il risultato come completato.
