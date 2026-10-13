---
status: resolved
resolution: fix-code
refs:
  - sync-run/Pushing changes
  - requirements/rules#sync-run
proposal: null
task: ec0ye6gs
origin: null
critical: false
option: 1
note: null
resolvedBy: fz9axufm
created: 2026-10-12T10:47:47.101Z
---
# Folder conflicts compare dates, the Requirement forbids it

## What happens

Quando una cartella è stata cambiata offline, la sincronizzazione confronta la data della modifica con quella del cloud: se il cloud è più recente la modifica locale viene scartata, altrimenti viene inviata e sostituisce la cartella del cloud. Così per le cartelle non vince sempre il cloud: una modifica locale più recente della versione del cloud la sostituisce.

## What should happen

Il Requirement sulle regole di sincronizzazione dice che per le cartelle **vince sempre il cloud, senza confronto di date**. Una modifica locale in attesa non deve sostituire la cartella del cloud durante una sincronizzazione completa.

## Fix options

### Drop offline folder changes whenever the cloud has the folder

Se il cloud ha già la cartella, la modifica locale in attesa viene scartata senza guardare le date, e la cartella arriva dal cloud con il download. Così si segue il Requirement alla lettera. Costo: una rinomina fatta offline su una cartella già nel cloud va persa anche se è la più recente; le cartelle create offline restano e vengono inviate.

### Keep the date check and rewrite the Requirement

Si mantiene il confronto: vince la modifica più recente tra locale e cloud, come per le note. Il Requirement, il Model e il Feature che dicono "vince il cloud" vanno riscritti in una Proposal. Costo: una cartella cambiata offline può sostituire una versione più vecchia del cloud, e la regola sulle cartelle cambia.

## Where in the code

lib/core/services/sync_service.dart: syncNow, passo della coda delle cartelle (controllo cloudIsNewer)
