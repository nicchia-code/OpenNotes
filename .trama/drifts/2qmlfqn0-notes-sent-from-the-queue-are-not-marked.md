---
status: resolved
resolution: fix-code
refs:
  - sync-run/Sending unsynced notes
proposal: null
task: 55inkfjf
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:26:45.339Z
---
# Notes sent from the queue are not marked as synced

## What happens

Le note inviate dalla coda vengono accettate dal cloud, ma sul dispositivo restano senza data di sincronizzazione. Alla sincronizzazione successiva vengono inviate di nuovo e solo allora risultano sincronizzate. Il passo delle note mai sincronizzate esamina così anche note già sul cloud, e una nota di benvenuto in questa situazione può essere scartata dal dispositivo.

## What should happen

Una nota risulta sincronizzata nel momento in cui il cloud accetta una sua modifica. La data di sincronizzazione resta vuota solo per le note che il cloud non ha ancora ricevuto, e il passo delle note mai sincronizzate deve trovare solo quelle.

## Fix options

### Mark each note as synced when its change is accepted

Ogni modifica accettata dal cloud segna subito la nota come sincronizzata, con la data di quel momento. Il passo delle note mai sincronizzate trova solo le note nuove, e le note già inviate non vengono reinviate né scartate per errore. Costo: un salvataggio locale in più per ogni modifica inviata.

### Mark the queued notes at the end of the run

Le note inviate dalla coda vengono segnate come sincronizzate alla fine della sincronizzazione, insieme a quelle del passo successivo. Costo: se la sincronizzazione si interrompe prima, le note restano senza data e vengono reinviate alla volta successiva; il controllo resta comunque legato alla fine della corsa.

## Where in the code

lib/core/services/sync_service.dart: syncNow, passo 1 (coda) e passo 3 (note mai sincronizzate).
