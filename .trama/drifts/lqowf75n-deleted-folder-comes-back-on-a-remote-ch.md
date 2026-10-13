---
status: resolved
resolution: fix-code
refs:
  - folder/Deleted
proposal: null
task: rkxqnocg
origin: null
critical: false
option: 1
note: null
resolvedBy: aq0a6puk
created: 2026-10-12T14:33:40.311Z
---
# Deleted folder comes back on a remote change

## What happens

Una cartella eliminata su questo dispositivo torna visibile quando arriva una modifica dal cloud, anche se la modifica è precedente all'eliminazione. Il ritorno avviene subito, senza attendere una sincronizzazione completa, e la cartella ricompare nella barra laterale e nella schermata Cartelle.

## What should happen

Il Model non prevede alcun passaggio da Deleted verso una cartella attiva che parta da una modifica remota: la cartella eliminata torna solo con il download, e solo se il cloud l'ha modificata dopo l'eliminazione. Una modifica remota precedente all'eliminazione non la riporta.

## Fix options

### Ignore remote changes to a deleted folder

Una modifica remota a una cartella eliminata qui non la riporta: la cartella resta eliminata finché la sua eliminazione è in coda, e torna solo con il download se il cloud l'ha cambiata dopo l'eliminazione, come descrive il Model. Il dispositivo deve sapere quali cartelle sono in coda per l'eliminazione. Costo: poche righe in più, nessun cambiamento visibile per l'utente nel caso normale.

### Keep the return on remote change

Il comportamento attuale resta: una modifica remota riporta la cartella anche se è precedente all'eliminazione. Nessun costo nel codice, ma la cartella eliminata può tornare per un ritardo della rete o per un'eco del proprio cambiamento, e l'utente deve eliminarla di nuovo.

## Where in the code

lib/core/services/sync_service.dart: gestione delle modifiche remote delle cartelle (handleRemoteFolderChange)
