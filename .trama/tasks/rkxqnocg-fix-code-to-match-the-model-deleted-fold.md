---
column: done
technical: false
refs:
  - folder/Deleted
drift: lqowf75n
proposal: null
agent: false
created: 2026-10-12T14:39:15.715Z
finished: 2026-10-12T14:40:26.478Z
---
# Fix code to match the Model: Deleted folder comes back on a remote change

## What happens

Una cartella eliminata su questo dispositivo torna visibile quando arriva una modifica dal cloud, anche se la modifica è precedente all'eliminazione. Il ritorno avviene subito, senza attendere una sincronizzazione completa, e la cartella ricompare nella barra laterale e nella schermata Cartelle.

## What should happen

Il Model non prevede alcun passaggio da Deleted verso una cartella attiva che parta da una modifica remota: la cartella eliminata torna solo con il download, e solo se il cloud l'ha modificata dopo l'eliminazione. Una modifica remota precedente all'eliminazione non la riporta.

## Chosen option

**Ignore remote changes to a deleted folder**

Una modifica remota a una cartella eliminata qui non la riporta: la cartella resta eliminata finché la sua eliminazione è in coda, e torna solo con il download se il cloud l'ha cambiata dopo l'eliminazione, come descrive il Model. Il dispositivo deve sapere quali cartelle sono in coda per l'eliminazione. Costo: poche righe in più, nessun cambiamento visibile per l'utente nel caso normale.

## Where in the code

lib/core/services/sync_service.dart: gestione delle modifiche remote delle cartelle (handleRemoteFolderChange)
