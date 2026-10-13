---
status: resolved
resolution: fix-code
refs:
  - sync-run/Pushing changes
proposal: null
task: p7iixyu3
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:26:45.234Z
---
# Queued welcome notes are sent to cloud even when it already has notes

## What happens

Le note di benvenuto create sul dispositivo prima dell'accesso entrano nella coda delle modifiche. Al primo accesso la coda viene inviata per prima, quindi le note finiscono sul cloud anche se il cloud ha già delle note. Poi, non risultando mai sincronizzate, vengono eliminate dal dispositivo e riscaricate dal cloud.

## What should happen

Una nota di benvenuto mai sincronizzata deve essere eliminata dal dispositivo, invece che inviata, quando il cloud ha almeno una nota. Con l'ordine fisso dei passi la coda parte prima di leggere il cloud, quindi per le note accodate questo controllo non avviene.

## Fix options

### Keep welcome notes out of the queue

Le note di benvenuto non creano più una modifica in coda: restano solo sul dispositivo finché la sincronizzazione non decide, e la regola di scarto funziona come scritta. Costo: se l'utente modifica una nota di benvenuto prima dell'accesso e il cloud ha già note, la modifica viene scartata insieme alla nota. Il modello delle modifiche in coda va cambiato.

### Read the cloud before sending the queue

La sincronizzazione legge prima il cloud e poi invia la coda, scartando le note di benvenuto accodate se il cloud ha già note. Costo: cambia l'ordine fisso dei passi, che i requisiti impongono, e va riscritto nel modello e nei requisiti.

### Send them and narrow the rule

Le note di benvenuto in coda vengono inviate come le altre modifiche, anche se il cloud ha già note, e la regola di scarto vale solo per le note mai accodate. Costo: il cloud riceve note di benvenuto che il requisito voleva scartate; il requisito va riscritto e il passo di scarto va ristretto.

## Where in the code

lib/core/services/sync_service.dart: syncNow, passo della coda e passo delle note mai sincronizzate; lib/main.dart: creazione delle note di benvenuto.
