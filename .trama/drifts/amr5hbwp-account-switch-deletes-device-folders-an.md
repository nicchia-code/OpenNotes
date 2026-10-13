---
status: resolved
resolution: fix-code
refs:
  - sync-run/Pushing changes
proposal: null
task: 5kb9dw8f
origin: null
critical: false
option: 1
note: null
resolvedBy: fz9axufm
created: 2026-10-12T10:47:41.515Z
---
# Account switch deletes device folders and their unsent changes too

## What happens

Quando accede un altro account, il dispositivo toglie anche tutte le cartelle dell'utente, comprese quelle create offline e mai inviate al cloud. Le note che stavano in quelle cartelle passano alla cartella "Note", anche se non erano ancora sincronizzate. Le modifiche alle cartelle tolte restano in coda e, se erano state cambiate offline, partono verso il nuovo account.

## What should happen

Il Model della sincronizzazione dice che al cambio di account vengono tolte solo le **note già sincronizzate**, con il loro file; le note mai sincronizzate restano. Non prevede nessuna rimozione di cartelle, e dice che note e cartelle presenti solo sul dispositivo non vengono toccate dal download.

## Fix options

### Remove only the synced notes, keep the folders

Il cambio di account toglie solo le note già sincronizzate, come scritto nel Model. Le cartelle restano sul dispositivo: quelle del cloud del precedente account tornano con il download, quelle create offline restano e vengono inviate al nuovo account. Costo: il nuovo account può ricevere cartelle create con il precedente, e va deciso se è accettabile.

### Record the folder removal in the Model

Al cambio di account le cartelle del precedente vengono tolte, come oggi, e il Model lo dichiara. Le cartelle mai inviate al cloud e le loro modifiche in coda vengono scartate, così il nuovo account non le riceve. Costo: una Proposal sul Model della sincronizzazione, e una cartella cambiata offline ma mai inviata va persa.

## Where in the code

lib/core/services/sync_service.dart: _adoptAccount, syncNow (coda delle cartelle); lib/core/services/database_service.dart: deleteFolder
