---
status: resolved
resolution: fix-code
refs:
  - sync-run/Pushing changes
  - requirements/rules#sync-run
proposal: null
task: 2c72pbof
origin: null
critical: false
option: 1
note: null
resolvedBy: fz9axufm
created: 2026-10-12T10:47:41.704Z
---
# Queued note saves overwrite a newer cloud copy

## What happens

Quando la coda parte, ogni modifica di nota in attesa viene scritta sul cloud così com'è, anche se il cloud ha già una versione più recente della stessa nota. Il cloud accetta la scrittura, e la nota risulta modificata con l'ora dell'invio: la versione più vecchia diventa quella che gli altri dispositivi scaricano.

## What should happen

Il Requirement sulle regole di sincronizzazione dice che per le note **vince l'ultimo che ha scritto**, confrontando la data di modifica: una modifica locale più vecchia della versione del cloud non deve sostituirla. Il Model dice solo che ogni salvataggio in coda invia la nota intera, senza condizioni.

## Fix options

### Skip queued saves older than the cloud copy

Prima di inviare un salvataggio in coda, la sincronizzazione legge la data di modifica del cloud per quella nota: se il cloud è più recente, il salvataggio locale viene scartato e resta la versione del cloud. Così vince l'ultimo che ha scritto, come da Requirement. Costo: una modifica fatta offline su una nota cambiata altrove si perde senza avviso, e c'è una lettura in più per ogni salvataggio.

### Keep sending queued saves, and fix the Requirement

La coda continua a inviare la nota intera senza confronti, come descritto nel Model. Il Requirement viene riscritto: per le note in coda vince il dispositivo, e il confronto della data resta solo per il download. Costo: una nota cambiata su un altro dispositivo può essere sovrascritta da una modifica locale più vecchia; il Requirement cambia in una Proposal.

## Where in the code

lib/core/services/sync_service.dart: syncNow, passo della coda (upsert delle note)
