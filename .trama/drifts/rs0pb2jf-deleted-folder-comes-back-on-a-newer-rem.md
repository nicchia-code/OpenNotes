---
status: resolved
resolution: fix-code
refs:
  - folder/Deleted
proposal: null
task: 0esbyxrb
origin: null
previous: lqowf75n
critical: false
option: 1
note: null
resolvedBy: gdnc8czu
created: 2026-10-17T17:51:28.847Z
---
# Deleted folder comes back on a newer remote change

## What happens

Una cartella eliminata su questo dispositivo, la cui eliminazione non è ancora arrivata al cloud, torna visibile non appena dal cloud arriva una modifica fatta dopo l'eliminazione. Il ritorno avviene subito, dal canale in tempo reale, senza aspettare la sincronizzazione: la cartella ricompare nella barra laterale e nella schermata Cartelle, mentre la sincronizzazione non l'ha ancora scaricata.

## What should happen

Una cartella eliminata è finale: nessuna modifica remota la riporta da sola. Torna solo con la sincronizzazione, e solo se il cloud l'ha cambiata dopo l'eliminazione: in quel caso l'eliminazione viene scartata e la cartella torna con il download. Il Model non prevede alcun passaggio da Deleted verso una cartella attiva che parta da una modifica ricevuta in tempo reale.

## Fix options

### Il canale in tempo reale non riporta la cartella eliminata

Una modifica ricevuta in tempo reale per una cartella eliminata qui viene ignorata mentre l'eliminazione è in attesa di essere inviata. La cartella resta eliminata e torna solo alla sincronizzazione successiva, se il cloud l'ha cambiata dopo l'eliminazione, come oggi per le modifiche più vecchie. Costo: poche righe in più nel canale; nessun effetto visibile, salvo che la cartella torna con qualche secondo di ritardo rispetto alla modifica del cloud.

### Il canale chiede una sincronizzazione invece di riportarla

Una modifica in tempo reale per una cartella eliminata qui non viene applicata direttamente: il dispositivo chiede un giro di sincronizzazione, che la confronta con l'eliminazione con la regola della data già prevista. Il risultato è lo stesso del primo caso, ma passa dal giro di sincronizzazione, come il Model descrive. Costo: un giro di sincronizzazione in più per ogni modifica di questo tipo, anche quando poi l'eliminazione resta.

## Where in the code

lib/core/services/sync_service.dart: handleRemoteFolderChange (ramo delle modifiche remote) e _storeCloudFolder (controllo dell'eliminazione in attesa)
