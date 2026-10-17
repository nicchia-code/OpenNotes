---
column: done
technical: false
refs:
  - realtime-channel/Listening/supabase.REMOTE_FOLDER_CHANGED
  - requirements/rules#realtime-channel
drift: mh11qz2q
proposal: null
agent: false
created: 2026-10-17T14:48:35.531Z
finished: 2026-10-17T14:51:18.238Z
---
# Fix code to match the Model: Cloud folder change already seen by revision is applied again

## What happens

Quando arriva la modifica di una cartella che il dispositivo ha già visto, per esempio l'eco di un proprio invio, la cartella locale viene sostituita comunque con quella del cloud, purché non ci sia una modifica in attesa più recente. Se l'eco arriva dopo che il dispositivo ha inviato una versione più recente, il nome della cartella torna per un momento alla versione vecchia, finché non arriva quella nuova.

## What should happen

Il Model di Listening dice che, per ogni modifica, se il dispositivo conosce già quella revisione o una successiva non succede nulla. Il Requirement rules#realtime-channel dice che una modifica con revisione minore o uguale alla revisione nota della cartella viene ignorata. Per le note questo controllo c'è; per le cartelle il confronto è solo con la data di modifica, anche se la revisione è già memorizzata.

## Chosen option

**Compare folder revisions as for notes**

Confrontare la revisione della cartella ricevuta con l'ultima revisione vista per quella cartella, come già avviene per le note: una cartella con revisione uguale o minore viene lasciata com'è. Il dispositivo conserva già la revisione delle cartelle, quindi non serve nuovo storage. Il giro di sincronizzazione applicherebbe la stessa regola alle cartelle che scarica.

## Where in the code

lib/core/services/sync_service.dart: _storeCloudFolder, chiamata da handleRemoteFolderChange; il controllo per revisione esiste solo in _alreadySeen, usata per le note in applyRemoteNote.
