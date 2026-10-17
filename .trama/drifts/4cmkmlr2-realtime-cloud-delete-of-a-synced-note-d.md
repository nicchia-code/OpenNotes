---
status: resolved
resolution: proposal
refs:
  - pending-change/Queued
  - realtime-channel/Listening
proposal: null
task: null
origin: null
previous: t8hb6zv7
critical: false
option: null
note: null
resolvedBy: 1mjjves7
created: 2026-10-17T09:45:38.701Z
---
# Realtime cloud delete of a synced note drops its queued saves at once

## What happens

Quando il canale in tempo reale riceve l'eliminazione di una nota nel cloud, il dispositivo elimina subito la nota e toglie dalla coda tutti i suoi salvataggi in attesa, senza che una sincronizzazione li esamini. Il Drift t8hb6zv7 aveva chiesto di lasciare la coda alla sincronizzazione successiva; il codice ha ripreso a scartarli subito, perché la rimozione della nota usa la stessa operazione dell'eliminazione definitiva dell'utente, che toglie i salvataggi delle note già sincronizzate.

## What should happen

Il Model della coda (pending-change, Queued) fa uscire un salvataggio solo con sync-run.CHANGE_SENT, sync-run.CHANGE_DISCARDED o sync-run.PREVIOUS_ACCOUNT_NOTE_REMOVED, oppure con note.PERMANENTLY_DELETED solo se l'eliminazione è dell'utente. Il Model del canale (realtime-channel, REMOTE_NOTE_DELETED) elimina la nota dal dispositivo senza toccare la coda; lo scarto del salvataggio spetta alla sincronizzazione successiva, che trova la nota assente nel cloud e la scarta come già previsto.

## Fix options

### Leave the queue to the sync run

Il ramo di eliminazione dal canale in tempo reale rimuove la nota dal dispositivo e le sue righe della coda restano; la sincronizzazione successiva le scarta con il ramo deletedInCloud, come il Model prevede. Il Model non cambia. Costo: fino alla sincronizzazione la coda conserva salvataggi di una nota che non esiste più localmente; l'utente non può modificarla, quindi nessun effetto visibile.

### Write the immediate discard in the Model

Il Model del canale e della coda aggiunge che un'eliminazione ricevuta dal cloud toglie subito i salvataggi in coda della nota già sincronizzata, e la transizione Discarded di pending-change accetta anche questo evento. Il codice resta com'è. Costo: due modifiche al Model e la regola è meno uniforme, perché le uscite della coda non sarebbero più tutte dalla sincronizzazione.

## Where in the code

lib/core/services/sync_service.dart: handleRemoteNoteChange (ramo RemoteNoteDelete, chiamata a permanentlyDeleteNote); lib/core/services/database_service.dart: permanentlyDeleteNote (rimozione delle righe upsert della nota con synced_at valorizzato).
