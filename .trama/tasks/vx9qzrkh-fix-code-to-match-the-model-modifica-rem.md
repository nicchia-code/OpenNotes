---
column: done
technical: false
refs:
  - realtime-channel/Listening/supabase.REMOTE_FOLDER_CHANGED
  - folder/Deleted
drift: 7qptr503
proposal: null
agent: false
created: 2026-10-12T18:00:24.467Z
finished: 2026-10-12T18:01:45.723Z
---
# Fix code to match the Model: Modifica remota di una cartella eliminata qui: il Model dice che sovrascrive sempre

## What happens

Se una cartella è stata eliminata su questo dispositivo e l'eliminazione non è ancora partita verso il cloud, una modifica della stessa cartella arrivata in tempo reale viene ignorata: la cartella resta eliminata e decide la sincronizzazione. Se l'eliminazione è già partita verso il cloud, la modifica arrivata dopo riporta la cartella sul dispositivo, con le sue note ancora in Note.

## What should happen

Il Model del canale dice che la modifica remota di una cartella la sostituisce **sempre**, senza confronti. Ma lo stato Deleted della cartella è finale e non riceve modifiche remote, e la sincronizzazione fa tornare una cartella eliminata solo se il cloud l'ha cambiata dopo l'eliminazione. Seguire la parola «sempre» farebbe ricomparire la cartella anche quando la sincronizzazione la eliminerà di nuovo.

## Chosen option

**Il canale ignora la modifica finché l'eliminazione è in coda**

La modifica remota viene ignorata mentre l'eliminazione locale è in coda, e la sincronizzazione decide con la regola della data già descritta. Dopo l'invio dell'eliminazione, una modifica in ritardo riporta comunque la cartella. Costo: il Model del canale va riscritto con questa eccezione a «sempre», e anche il ritorno dopo l'invio va descritto, perché oggi non lo è.

## Where in the code

lib/core/services/sync_service.dart: handleRemoteFolderChange (controllo dell'eliminazione in coda prima di salvare la cartella)
