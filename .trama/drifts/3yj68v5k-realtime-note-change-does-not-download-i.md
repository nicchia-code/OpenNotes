---
status: resolved
resolution: fix-code
refs:
  - realtime-channel/Listening/supabase.REMOTE_NOTE_CHANGED
  - requirements/rules#realtime-channel
proposal: null
task: xo4exsv7
origin: null
critical: false
option: 1
note: null
resolvedBy: tqf85in9
created: 2026-10-17T17:17:25.966Z
---
# Realtime note change does not download its missing attachments

## What happens

Quando il canale in tempo reale riceve una nota che sostituisce la copia del dispositivo, la nota viene aggiornata ma le **immagini e i disegni** che mancano non vengono scaricati. Il dispositivo li scarica solo nel giro di sincronizzazione successivo, che il canale non avvia: fino ad allora la nota compare con gli allegati mancanti.

## What should happen

Quando una nota ricevuta dal canale sostituisce la copia locale, il dispositivo deve scaricare subito le **immagini e i disegni** che mancano nel vault. Un download non riuscito viene annotato nel registro e ritentato al giro successivo.

## Fix options

### Download the missing attachments inside the change

Quando una nota ricevuta dal canale sostituisce la copia locale, il dispositivo scarica subito le immagini e i disegni che mancano, prima di passare alla modifica successiva in coda. La nota compare già con i suoi allegati. Costo: ogni modifica in arrivo aspetta i download della nota che la precede, quindi con molti allegati la coda rallenta. Un download non riuscito viene annotato e ritentato al giro successivo, come oggi.

### Download the missing attachments in the background

La nota viene applicata e mostrata subito; gli allegati mancanti vengono scaricati a parte, senza bloccare le modifiche successive in coda. Le immagini e i disegni compaiono appena il download finisce. Costo: serve un percorso di download separato dalla coda, e l'ordine in cui compaiono gli allegati non è garantito. Un download non riuscito viene annotato e ritentato al giro successivo.

## Where in the code

lib/core/services/sync_service.dart: applyRemoteNote (called by handleRemoteNoteChange) and _downloadAttachmentsOfAllNotes, which runs only inside _performRun; test/sync_pulling_attachments_test.dart asserts that applying a cloud copy downloads nothing.
