---
column: done
technical: false
refs:
  - sync-run/Pushing changes
drift: 6tbds6iq
proposal: null
agent: false
created: 2026-10-12T07:38:53.747Z
finished: 2026-10-12T07:43:49.829Z
---
# Fix code to match the Model: Queued welcome notes are sent to cloud even when it already has notes

## What happens

Le note di benvenuto create sul dispositivo prima dell'accesso entrano nella coda delle modifiche. Al primo accesso la coda viene inviata per prima, quindi le note finiscono sul cloud anche se il cloud ha già delle note. Poi, non risultando mai sincronizzate, vengono eliminate dal dispositivo e riscaricate dal cloud.

## What should happen

Una nota di benvenuto mai sincronizzata deve essere eliminata dal dispositivo, invece che inviata, quando il cloud ha almeno una nota. Con l'ordine fisso dei passi la coda parte prima di leggere il cloud, quindi per le note accodate questo controllo non avviene.

## Chosen option

**Keep welcome notes out of the queue**

Le note di benvenuto non creano più una modifica in coda: restano solo sul dispositivo finché la sincronizzazione non decide, e la regola di scarto funziona come scritta. Costo: se l'utente modifica una nota di benvenuto prima dell'accesso e il cloud ha già note, la modifica viene scartata insieme alla nota. Il modello delle modifiche in coda va cambiato.

## Where in the code

lib/core/services/sync_service.dart: syncNow, passo della coda e passo delle note mai sincronizzate; lib/main.dart: creazione delle note di benvenuto.
