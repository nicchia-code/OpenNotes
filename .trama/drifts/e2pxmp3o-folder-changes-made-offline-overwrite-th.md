---
status: resolved
resolution: fix-code
refs:
  - cloud-sync
proposal: null
task: i94kuyv0
origin: null
critical: false
option: 1
note: null
resolvedBy: p136jufl
created: 2026-10-12T08:00:55.179Z
---
# Folder changes made offline overwrite the cloud version

## What happens

Una cartella cambiata sul dispositivo viene inviata al cloud prima di scaricare le cartelle. Se nel frattempo la stessa cartella è stata cambiata su un altro dispositivo, la modifica locale sovrascrive quella più recente del cloud, e l'altro cambiamento sparisce senza avviso.

## What should happen

Per le cartelle vale la regola **vince il cloud**: durante una sincronizzazione completa la versione più recente nel cloud deve restare, e una modifica locale in attesa non deve sostituirla.

## Fix options

### Il cloud vince davvero sulle cartelle

Prima di inviare una modifica di cartella, la sincronizzazione controlla il cloud: se la cartella lì è cambiata dopo, la modifica locale viene scartata e resta la versione del cloud. Nessuna cartella viene sovrascritta, ma un cambiamento fatto offline può scomparire senza che l'utente se ne accorga.

### Vince la modifica locale

Si mantiene il comportamento attuale: la modifica in attesa parte per prima e sostituisce il cloud. L'ultima modifica fatta sul dispositivo non si perde mai, ma la regola scritta nel modello diventa falsa e va riscritta, perché per le cartelle non vincerebbe più il cloud.

## Where in the code

lib/core/services/sync_service.dart (syncNow: coda delle cartelle, poi scaricamento delle cartelle)
