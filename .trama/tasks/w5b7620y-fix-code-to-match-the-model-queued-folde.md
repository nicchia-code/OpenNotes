---
column: done
technical: false
refs:
  - sync-run/Pushing changes
  - requirements/rules#sync-run
drift: dgy738pi
proposal: null
agent: false
created: 2026-10-12T14:20:57.126Z
finished: 2026-10-12T14:22:43.566Z
---
# Fix code to match the Model: Queued folder create or rename dropped when the cloud already has the folder

## What happens

Quando la sincronizzazione invia una cartella creata o rinominata offline, se il cloud ha già quella cartella la modifica viene scartata. Il cloud vince, senza alcun confronto di date, e al download il nome locale va perso: la cartella torna com'era sul cloud.

## What should happen

Creazione e rinomina di una cartella in coda devono sovrascrivere la cartella del cloud senza confronto di date, anche se il cloud la ha già. Solo l'eliminazione passa dal confronto con la data di modifica.

## Chosen option

**Inviare sempre la cartella in coda**

Quando la cartella è in coda, inviarla al cloud e sovrascrivere la copia del cloud, come prescrive la regola. Nessun confronto di date da aggiungere. Costo: una rinomina fatta altrove sulla stessa cartella viene sovrascritta, come la regola prevede.

## Where in the code

lib/core/services/sync_service.dart, funzione syncNow, passo di invio della coda per le cartelle (creazione o rinomina).
