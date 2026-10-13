---
status: resolved
resolution: fix-code
refs:
  - pending-change/Queued
  - requirements/rules#pending-change
proposal: null
task: hy3tp0rf
origin: null
critical: false
option: 1
note: null
resolvedBy: ke2oiwmu
created: 2026-10-12T15:08:35.774Z
---
# Queued folder create or rename is discarded when the folder is gone from both sides

## What happens

Quando la sincronizzazione arriva a una creazione o rinomina di cartella che il cloud non ha più e che il dispositivo non ha più, il cambiamento viene tolto dalla coda senza essere inviato. Nessun avviso all'utente, e la cartella non ricompare né sul cloud né sul dispositivo.

## What should happen

Il Model dice che un cambiamento in coda viene scartato solo se è un salvataggio di nota non più recente, un salvataggio di nota eliminata nel cloud, oppure un'eliminazione più vecchia dell'ultima modifica sul cloud. Il Requirement dice che creazione e rinomina di cartelle sovrascrivono la cartella del cloud senza confronto di date, anche se il cloud la ha già.

## Fix options

### Document the discard in the Model

Aggiungere al Model di pending-change lo scarto delle creazioni e delle rinomine di cartelle già eliminate ovunque, così il Model descrive il comportamento del codice. Costo: una voce in più nel Model, nessun cambiamento al codice.

### Send folder creates and renames without the check

Inviare sempre creazione e rinomina, anche quando il cloud e il dispositivo non hanno più la cartella, e farla ricomparire. Costo: una cartella eliminata altrove può tornare, ma il comportamento segue alla lettera il Requirement.

## Where in the code

lib/core/services/sync_service.dart, sync step for queued folder upsert (cloudRow == null && !folderExists)
