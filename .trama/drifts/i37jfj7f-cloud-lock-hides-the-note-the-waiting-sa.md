---
status: resolved
resolution: proposal
refs:
  - note-content-save
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: famz2y49
created: 2026-10-18T17:35:30.181Z
---
# Cloud lock hides the note: the waiting save is written at once, the Model has no such exit

## What happens

Quando una versione remota protetta mette il lucchetto alla nota con una modifica in attesa, il codice consegna la modifica e la scrive subito, prima di nascondere la nota, senza aspettare lo scadere dell'attesa.

## What should happen

Il Model di note-content-save non ha nessuna transizione per sync-run.CLOUD_NOTE_APPLIED né per realtime-channel.CLOUD_NOTE_APPLIED: la versione in attesa resterebbe in attesa fino allo scadere dell'attesa. Il Model di note-editor (stato Save pending) descrive solo che la versione remota non viene caricata.

## Fix options

### Add the cloud-lock handover to the Model: the waiting save is written at once

Aggiungere a note-content-save una transizione per la versione remota protetta: la modifica in attesa viene scritta subito, come fanno i comandi sulla nota (Task 4v9nq4kk). Il codice resta com'è.

### Remove the immediate write: the waiting save waits the usual time

Il codice non scrive subito la modifica in attesa al lucchetto da cloud: la nota viene nascosta e la modifica viene scritta allo scadere dell'attesa, come descritto dal Model di note-content-save. Si annulla la scelta della Task 4v9nq4kk.

## Where in the code

lib/core/state/notes_provider.dart: listener of remote changes (CloudNoteApplied with isLocked: deliverWaitingEdits, relockNote, flushPendingContent)
