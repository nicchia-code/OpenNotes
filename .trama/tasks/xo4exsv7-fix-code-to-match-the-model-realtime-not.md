---
column: done
technical: false
refs:
  - realtime-channel/Listening/supabase.REMOTE_NOTE_CHANGED
  - requirements/rules#realtime-channel
drift: 3yj68v5k
proposal: null
agent: false
created: 2026-10-17T17:39:37.185Z
finished: 2026-10-17T17:41:32.369Z
---
# Fix code to match the Model: Realtime note change does not download its missing attachments

## What happens

Quando il canale in tempo reale riceve una nota che sostituisce la copia del dispositivo, la nota viene aggiornata ma le **immagini e i disegni** che mancano non vengono scaricati. Il dispositivo li scarica solo nel giro di sincronizzazione successivo, che il canale non avvia: fino ad allora la nota compare con gli allegati mancanti.

## What should happen

Quando una nota ricevuta dal canale sostituisce la copia locale, il dispositivo deve scaricare subito le **immagini e i disegni** che mancano nel vault. Un download non riuscito viene annotato nel registro e ritentato al giro successivo.

## Chosen option

**Download the missing attachments inside the change**

Quando una nota ricevuta dal canale sostituisce la copia locale, il dispositivo scarica subito le immagini e i disegni che mancano, prima di passare alla modifica successiva in coda. La nota compare già con i suoi allegati. Costo: ogni modifica in arrivo aspetta i download della nota che la precede, quindi con molti allegati la coda rallenta. Un download non riuscito viene annotato e ritentato al giro successivo, come oggi.

## Where in the code

lib/core/services/sync_service.dart: applyRemoteNote (called by handleRemoteNoteChange) and _downloadAttachmentsOfAllNotes, which runs only inside _performRun; test/sync_pulling_attachments_test.dart asserts that applying a cloud copy downloads nothing.
