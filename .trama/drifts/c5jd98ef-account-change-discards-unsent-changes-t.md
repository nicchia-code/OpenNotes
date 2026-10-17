---
status: resolved
resolution: proposal
refs:
  - pending-change/Pending/sync-run.PREVIOUS_ACCOUNT_NOTE_REMOVED
proposal: null
task: null
origin: yc1qkauv
critical: false
option: null
note: null
resolvedBy: hp4kwvga
created: 2026-10-17T11:38:44.398Z
---
# Account change discards unsent changes the Model no longer names in pending-change

## What happens

Quando cambia l'account, le modifiche in coda delle note già sincronizzate dell'account precedente vengono tolte dalla coda senza essere inviate. Dopo la Proposal 634nfp49 la macchina pending-change non nomina più questo caso, mentre sync-run dice ancora che il cambio di account scarta i cambiamenti in attesa.

## What should happen

sync-run dice che il cambio di account elimina le note e scarta i loro cambiamenti in attesa; pending-change non deve più avere la transizione. Le due macchine si contraddicono: il cambiamento in coda non ha più una uscita nel Model.

## Where in the code

lib/core/services/sync_service.dart, metodo _adoptAccount (scarto delle modifiche in coda delle note del vecchio account); lib/core/services/database_service.dart, permanentlyDeleteNote
