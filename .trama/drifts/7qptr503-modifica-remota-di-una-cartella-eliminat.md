---
status: resolved
resolution: fix-code
refs:
  - realtime-channel/Listening/supabase.REMOTE_FOLDER_CHANGED
  - folder/Deleted
proposal: null
task: vx9qzrkh
origin: null
critical: false
option: 1
note: null
resolvedBy: oasankgu
created: 2026-10-12T17:50:09.187Z
---
# Modifica remota di una cartella eliminata qui: il Model dice che sovrascrive sempre

## What happens

Se una cartella è stata eliminata su questo dispositivo e l'eliminazione non è ancora partita verso il cloud, una modifica della stessa cartella arrivata in tempo reale viene ignorata: la cartella resta eliminata e decide la sincronizzazione. Se l'eliminazione è già partita verso il cloud, la modifica arrivata dopo riporta la cartella sul dispositivo, con le sue note ancora in Note.

## What should happen

Il Model del canale dice che la modifica remota di una cartella la sostituisce **sempre**, senza confronti. Ma lo stato Deleted della cartella è finale e non riceve modifiche remote, e la sincronizzazione fa tornare una cartella eliminata solo se il cloud l'ha cambiata dopo l'eliminazione. Seguire la parola «sempre» farebbe ricomparire la cartella anche quando la sincronizzazione la eliminerà di nuovo.

## Fix options

### Il canale ignora la modifica finché l'eliminazione è in coda

La modifica remota viene ignorata mentre l'eliminazione locale è in coda, e la sincronizzazione decide con la regola della data già descritta. Dopo l'invio dell'eliminazione, una modifica in ritardo riporta comunque la cartella. Costo: il Model del canale va riscritto con questa eccezione a «sempre», e anche il ritorno dopo l'invio va descritto, perché oggi non lo è.

### Il canale sovrascrive sempre, come scritto

La cartella torna subito con la versione del cloud, anche se è eliminata qui. Se la sincronizzazione la eliminerà di nuovo, perché il cloud l'ha cambiata prima dell'eliminazione, compare e scompare. Costo: un ritorno visibile e poi un'altra scomparsa, e lo stato Deleted della cartella va cambiato perché accetti la modifica remota.

## Where in the code

lib/core/services/sync_service.dart: handleRemoteFolderChange (controllo dell'eliminazione in coda prima di salvare la cartella)
