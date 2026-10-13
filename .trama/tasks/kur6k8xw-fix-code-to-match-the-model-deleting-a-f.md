---
column: done
technical: false
refs:
  - folder/User folder
  - pending-change/Queued
drift: sdkve31p
proposal: null
agent: false
created: 2026-10-12T18:23:16.173Z
finished: 2026-10-12T18:31:21.998Z
---
# Fix code to match the Model: Deleting a folder drops its queued creation or rename, the Model does not say so

## What happens

Quando l'utente elimina una cartella, il dispositivo toglie dalla coda le creazioni e le rinomine di quella cartella non ancora inviate, e mette in coda solo l'eliminazione. Queste modifiche non arrivano mai al cloud e non vengono registrate come scartate.

## What should happen

Il Model dell'eliminazione dice soltanto che l'eliminazione viene messa in coda. Il Model del cambiamento in coda dice che una creazione o una rinomina resta in coda finché la sincronizzazione non la invia o non la scarta, e che gli scarti previsti sono solo quelli della sincronizzazione o del cambio di account.

## Chosen option

**Keep the drop and describe it in the Model**

Eliminando una cartella, le sue creazioni e rinomine non ancora inviate vengono tolte, perché la cartella sparisce comunque. Il Model dell'eliminazione e del cambiamento in coda va aggiornato con questa uscita. Costo: nel caso normale nulla si vede; solo se il cloud ha modificato la cartella dopo l'eliminazione, questa torna con il nome del cloud e la rinomina offline è persa.

## Where in the code

lib/core/services/sync_service.dart, notifyFolderChanged: with isDelete it calls removeSyncActionsFor('folder', id) before queuing the delete.
