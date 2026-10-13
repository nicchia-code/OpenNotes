---
status: resolved
resolution: fix-code
refs:
  - folder/User folder
  - pending-change/Queued
proposal: null
task: kur6k8xw
origin: null
critical: false
option: 1
note: null
resolvedBy: 32w3ze0y
created: 2026-10-12T18:16:11.953Z
---
# Deleting a folder drops its queued creation or rename, the Model does not say so

## What happens

Quando l'utente elimina una cartella, il dispositivo toglie dalla coda le creazioni e le rinomine di quella cartella non ancora inviate, e mette in coda solo l'eliminazione. Queste modifiche non arrivano mai al cloud e non vengono registrate come scartate.

## What should happen

Il Model dell'eliminazione dice soltanto che l'eliminazione viene messa in coda. Il Model del cambiamento in coda dice che una creazione o una rinomina resta in coda finché la sincronizzazione non la invia o non la scarta, e che gli scarti previsti sono solo quelli della sincronizzazione o del cambio di account.

## Fix options

### Keep the drop and describe it in the Model

Eliminando una cartella, le sue creazioni e rinomine non ancora inviate vengono tolte, perché la cartella sparisce comunque. Il Model dell'eliminazione e del cambiamento in coda va aggiornato con questa uscita. Costo: nel caso normale nulla si vede; solo se il cloud ha modificato la cartella dopo l'eliminazione, questa torna con il nome del cloud e la rinomina offline è persa.

### Send the queued changes before the delete

Creazioni e rinomine in coda restano e vengono inviate prima dell'eliminazione, come le altre modifiche in coda, così il cloud riceve ogni passaggio. Costo: più richieste verso il cloud per cartelle poi eliminate, e un errore nell'invio blocca anche l'eliminazione.

## Where in the code

lib/core/services/sync_service.dart, notifyFolderChanged: with isDelete it calls removeSyncActionsFor('folder', id) before queuing the delete.
