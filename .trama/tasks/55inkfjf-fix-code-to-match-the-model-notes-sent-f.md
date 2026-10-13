---
column: done
technical: false
refs:
  - sync-run/Sending unsynced notes
drift: 2qmlfqn0
proposal: null
agent: false
created: 2026-10-12T07:38:53.754Z
finished: 2026-10-12T07:44:48.426Z
---
# Fix code to match the Model: Notes sent from the queue are not marked as synced

## What happens

Le note inviate dalla coda vengono accettate dal cloud, ma sul dispositivo restano senza data di sincronizzazione. Alla sincronizzazione successiva vengono inviate di nuovo e solo allora risultano sincronizzate. Il passo delle note mai sincronizzate esamina così anche note già sul cloud, e una nota di benvenuto in questa situazione può essere scartata dal dispositivo.

## What should happen

Una nota risulta sincronizzata nel momento in cui il cloud accetta una sua modifica. La data di sincronizzazione resta vuota solo per le note che il cloud non ha ancora ricevuto, e il passo delle note mai sincronizzate deve trovare solo quelle.

## Chosen option

**Mark each note as synced when its change is accepted**

Ogni modifica accettata dal cloud segna subito la nota come sincronizzata, con la data di quel momento. Il passo delle note mai sincronizzate trova solo le note nuove, e le note già inviate non vengono reinviate né scartate per errore. Costo: un salvataggio locale in più per ogni modifica inviata.

## Where in the code

lib/core/services/sync_service.dart: syncNow, passo 1 (coda) e passo 3 (note mai sincronizzate).
