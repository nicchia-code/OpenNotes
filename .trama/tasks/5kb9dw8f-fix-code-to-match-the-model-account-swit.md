---
column: done
technical: false
refs:
  - sync-run/Pushing changes
drift: amr5hbwp
proposal: null
agent: false
created: 2026-10-12T10:59:40.556Z
finished: 2026-10-12T11:07:02.526Z
---
# Fix code to match the Model: Account switch deletes device folders and their unsent changes too

## What happens

Quando accede un altro account, il dispositivo toglie anche tutte le cartelle dell'utente, comprese quelle create offline e mai inviate al cloud. Le note che stavano in quelle cartelle passano alla cartella "Note", anche se non erano ancora sincronizzate. Le modifiche alle cartelle tolte restano in coda e, se erano state cambiate offline, partono verso il nuovo account.

## What should happen

Il Model della sincronizzazione dice che al cambio di account vengono tolte solo le **note già sincronizzate**, con il loro file; le note mai sincronizzate restano. Non prevede nessuna rimozione di cartelle, e dice che note e cartelle presenti solo sul dispositivo non vengono toccate dal download.

## Chosen option

**Remove only the synced notes, keep the folders**

Il cambio di account toglie solo le note già sincronizzate, come scritto nel Model. Le cartelle restano sul dispositivo: quelle del cloud del precedente account tornano con il download, quelle create offline restano e vengono inviate al nuovo account. Costo: il nuovo account può ricevere cartelle create con il precedente, e va deciso se è accettabile.

## Where in the code

lib/core/services/sync_service.dart: _adoptAccount, syncNow (coda delle cartelle); lib/core/services/database_service.dart: deleteFolder
