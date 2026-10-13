---
status: resolved
resolution: fix-code
refs:
  - sync-run.CLOUD_DELETED_NOTE_REMOVED
  - sync-run.SAMPLE_NOTE_DISCARDED
  - sync-run.PREVIOUS_ACCOUNT_NOTE_REMOVED
proposal: null
task: 2drw4om1
origin: null
critical: false
option: 1
note: null
resolvedBy: v0urpc7v
created: 2026-10-13T12:44:38.002Z
---
# Notes removed by a sync run are not reported to the lists until the run ends

## What happens

Quando una sincronizzazione elimina dal dispositivo una nota (il cloud non la ha più, il cambio di account, una nota di benvenuto scartata perché il cloud ha già note), la rimozione non viene comunicata: syncNow non emette nulla su remoteChanges. Le liste si ricaricano solo quando una nota viene applicata dal cloud o alla fine della sincronizzazione, quindi la nota eliminata resta nell'elenco fino a quel momento.

## What should happen

Il Model di sync-run dice che ogni nota eliminata dalla sincronizzazione emette il proprio evento (CLOUD_DELETED_NOTE_REMOVED, SAMPLE_NOTE_DISCARDED, PREVIOUS_ACCOUNT_NOTE_REMOVED) verso la nota, che passa a Deleted. Il tempo reale, per la stessa rimozione, emette CLOUD_NOTE_REMOVED e le liste si aggiornano durante la sincronizzazione: le rimozioni della sincronizzazione devono seguire lo stesso percorso.

## Fix options

### Emit CloudNoteRemoved for every note the run removes

In syncNow e in _adoptAccount, per ogni nota eliminata dal dispositivo (cloud, cambio di account, benvenuto scartato), aggiungere CloudNoteRemoved(id) a remoteChanges. Le liste si ricaricano già a ogni evento, anche durante la sincronizzazione. Costo: poche righe, e la documentazione di CloudNoteRemoved va aggiornata perché non riguarda solo le eliminazioni dal cloud.

### Reload lists after each removing step

Dopo il passo di invio della coda e dopo quello delle note mai sincronizzate, ricaricare cartelle, tag ed elenco se il passo ha rimosso note, senza un evento per nota. Costo: un ricaricamento per passo invece che uno per nota; serve un segnale nuovo verso NotesProvider durante la sincronizzazione.

## Where in the code

lib/core/services/sync_service.dart (syncNow, _adoptAccount, _sendUnsyncedNote); lib/core/state/notes_provider.dart (_onSyncChanged, remoteChanges listener)
