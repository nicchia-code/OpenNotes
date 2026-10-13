---
column: done
technical: false
refs:
  - cloud-sync
drift: e2pxmp3o
proposal: null
agent: false
created: 2026-10-12T08:09:28.344Z
finished: 2026-10-12T08:15:56.006Z
---
# Fix code to match the Model: Folder changes made offline overwrite the cloud version

## What happens

Una cartella cambiata sul dispositivo viene inviata al cloud prima di scaricare le cartelle. Se nel frattempo la stessa cartella è stata cambiata su un altro dispositivo, la modifica locale sovrascrive quella più recente del cloud, e l'altro cambiamento sparisce senza avviso.

## What should happen

Per le cartelle vale la regola **vince il cloud**: durante una sincronizzazione completa la versione più recente nel cloud deve restare, e una modifica locale in attesa non deve sostituirla.

## Chosen option

**Il cloud vince davvero sulle cartelle**

Prima di inviare una modifica di cartella, la sincronizzazione controlla il cloud: se la cartella lì è cambiata dopo, la modifica locale viene scartata e resta la versione del cloud. Nessuna cartella viene sovrascritta, ma un cambiamento fatto offline può scomparire senza che l'utente se ne accorga.

## Where in the code

lib/core/services/sync_service.dart (syncNow: coda delle cartelle, poi scaricamento delle cartelle)
