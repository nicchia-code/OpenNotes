---
column: done
technical: false
refs:
  - sync-run/Pushing changes
  - requirements/rules#sync-run
drift: 9vrlkid4
proposal: null
agent: false
created: 2026-10-12T10:59:40.562Z
finished: 2026-10-12T11:13:54.981Z
---
# Fix code to match the Model: Queued note saves overwrite a newer cloud copy

## What happens

Quando la coda parte, ogni modifica di nota in attesa viene scritta sul cloud così com'è, anche se il cloud ha già una versione più recente della stessa nota. Il cloud accetta la scrittura, e la nota risulta modificata con l'ora dell'invio: la versione più vecchia diventa quella che gli altri dispositivi scaricano.

## What should happen

Il Requirement sulle regole di sincronizzazione dice che per le note **vince l'ultimo che ha scritto**, confrontando la data di modifica: una modifica locale più vecchia della versione del cloud non deve sostituirla. Il Model dice solo che ogni salvataggio in coda invia la nota intera, senza condizioni.

## Chosen option

**Skip queued saves older than the cloud copy**

Prima di inviare un salvataggio in coda, la sincronizzazione legge la data di modifica del cloud per quella nota: se il cloud è più recente, il salvataggio locale viene scartato e resta la versione del cloud. Così vince l'ultimo che ha scritto, come da Requirement. Costo: una modifica fatta offline su una nota cambiata altrove si perde senza avviso, e c'è una lettura in più per ogni salvataggio.

## Where in the code

lib/core/services/sync_service.dart: syncNow, passo della coda (upsert delle note)
