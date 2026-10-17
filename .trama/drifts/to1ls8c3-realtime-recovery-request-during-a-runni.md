---
status: resolved
resolution: dismissed
refs:
  - sync-run
proposal: null
task: null
origin: d3oq4nql
critical: false
option: null
note: null
created: 2026-10-17T11:55:37.151Z
---
# Realtime recovery request during a running sync is dropped

## What happens

Se il canale si ricollega mentre un giro è in corso, syncNow esce subito perché _isSyncing è vero: la richiesta di recupero va persa e le modifiche fatte altrove durante l'interruzione aspettano il prossimo avvio.

## What should happen

Il Model sync-run: in Running, realtime-channel.RECONNECTED dà giro subito, e ogni avvio che arriva durante il giro viene ricordato per il giro successivo.

## Fix options

### Ricordare la richiesta durante il giro

Registrare la richiesta mentre il giro è in corso e avviarne un altro al termine, come prescrive il Model sync-run.

### Coda unica dei giri

Far passare ogni avvio e ogni recupero da una coda di richieste di giro gestita dal motore di sincronizzazione.

### Attendere il prossimo avvio

Accettare il ritardo fino al prossimo avvio periodico o ritorno in primo piano, senza ricordare la richiesta; cambia il Model.

## Where in the code

lib/core/services/sync_service.dart: syncNow (uscita anticipata con _isSyncing) e _setupRealtimeSubscription (onStatus che chiama syncNow).
