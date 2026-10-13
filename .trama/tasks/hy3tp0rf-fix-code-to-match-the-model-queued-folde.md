---
column: done
technical: false
refs:
  - pending-change/Queued
  - requirements/rules#pending-change
drift: atb46geu
proposal: null
agent: false
created: 2026-10-12T15:18:03.637Z
finished: 2026-10-12T16:37:49.032Z
---
# Fix code to match the Model: Queued folder create or rename is discarded when the folder is gone from both sides

## What happens

Quando la sincronizzazione arriva a una creazione o rinomina di cartella che il cloud non ha più e che il dispositivo non ha più, il cambiamento viene tolto dalla coda senza essere inviato. Nessun avviso all'utente, e la cartella non ricompare né sul cloud né sul dispositivo.

## What should happen

Il Model dice che un cambiamento in coda viene scartato solo se è un salvataggio di nota non più recente, un salvataggio di nota eliminata nel cloud, oppure un'eliminazione più vecchia dell'ultima modifica sul cloud. Il Requirement dice che creazione e rinomina di cartelle sovrascrivono la cartella del cloud senza confronto di date, anche se il cloud la ha già.

## Chosen option

**Document the discard in the Model**

Aggiungere al Model di pending-change lo scarto delle creazioni e delle rinomine di cartelle già eliminate ovunque, così il Model descrive il comportamento del codice. Costo: una voce in più nel Model, nessun cambiamento al codice.

## Where in the code

lib/core/services/sync_service.dart, sync step for queued folder upsert (cloudRow == null && !folderExists)
