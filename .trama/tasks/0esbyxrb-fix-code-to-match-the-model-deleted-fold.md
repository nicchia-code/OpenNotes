---
column: done
technical: false
refs:
  - folder/Deleted
drift: rs0pb2jf
proposal: null
agent: false
created: 2026-10-17T18:07:16.477Z
finished: 2026-10-17T18:08:44.427Z
---
# Fix code to match the Model: Deleted folder comes back on a newer remote change

## What happens

Una cartella eliminata su questo dispositivo, la cui eliminazione non è ancora arrivata al cloud, torna visibile non appena dal cloud arriva una modifica fatta dopo l'eliminazione. Il ritorno avviene subito, dal canale in tempo reale, senza aspettare la sincronizzazione: la cartella ricompare nella barra laterale e nella schermata Cartelle, mentre la sincronizzazione non l'ha ancora scaricata.

## What should happen

Una cartella eliminata è finale: nessuna modifica remota la riporta da sola. Torna solo con la sincronizzazione, e solo se il cloud l'ha cambiata dopo l'eliminazione: in quel caso l'eliminazione viene scartata e la cartella torna con il download. Il Model non prevede alcun passaggio da Deleted verso una cartella attiva che parta da una modifica ricevuta in tempo reale.

## Chosen option

**Il canale in tempo reale non riporta la cartella eliminata**

Una modifica ricevuta in tempo reale per una cartella eliminata qui viene ignorata mentre l'eliminazione è in attesa di essere inviata. La cartella resta eliminata e torna solo alla sincronizzazione successiva, se il cloud l'ha cambiata dopo l'eliminazione, come oggi per le modifiche più vecchie. Costo: poche righe in più nel canale; nessun effetto visibile, salvo che la cartella torna con qualche secondo di ritardo rispetto alla modifica del cloud.

## Where in the code

lib/core/services/sync_service.dart: handleRemoteFolderChange (ramo delle modifiche remote) e _storeCloudFolder (controllo dell'eliminazione in attesa)
