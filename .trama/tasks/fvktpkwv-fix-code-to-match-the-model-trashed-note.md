---
column: done
technical: false
refs:
  - note/In trash
  - realtime-channel/Listening/supabase.REMOTE_NOTE_DELETED
drift: k305l07x
proposal: null
agent: false
created: 2026-10-17T13:41:35.324Z
finished: 2026-10-17T13:51:56.264Z
---
# Fix code to match the Model: Trashed note deleted in the cloud is kept, the Model removes it

## What happens

Quando il canale in tempo reale riceve l'eliminazione di una nota che sta nel cestino, il dispositivo la lascia nel cestino con il suo contenuto. Una sua modifica ancora in attesa non viene inviata: al giro successivo viene scartata, e la nota resta sul dispositivo come se il cloud non l'avesse eliminata.

## What should happen

Il Model di realtime-channel (REMOTE_NOTE_DELETED e CLOUD_NOTE_REMOVED) dice che una nota nel cestino eliminata nel cloud viene rimossa dal dispositivo insieme al suo file, senza accodare nulla, come le altre note; lo stesso vale per la transizione In trash di note. La decisione del Drift nesjiteo, risolta con 'lasciare la nota nel cestino', non è più quella descritta dal Model.

## Chosen option

**Remove the trashed note as the Model says**

La nota nel cestino viene eliminata dal dispositivo insieme al suo file nel vault, e le sue modifiche in attesa vengono scartate, come per le altre note. Costo: il cestino perde una nota che l'utente non ha eliminato direttamente, e la decisione del Drift nesjiteo va superata.

## Where in the code

lib/core/services/sync_service.dart, _removeRemoteNote: esce subito quando la nota è nel cestino (local.isDeleted). Lo stesso ramo è nella sincronizzazione completa, nella parte che esamina le note eliminate nel cloud.
