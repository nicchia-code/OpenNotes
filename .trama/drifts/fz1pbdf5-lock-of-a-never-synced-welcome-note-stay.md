---
status: resolved
resolution: fix-code
refs:
  - note-access/Unprotected
  - requirements/rules#note-access
proposal: null
task: coljj4w7
origin: null
critical: false
option: 1
note: null
resolvedBy: 37m9hzhb
created: 2026-10-13T05:42:04.204Z
---
# Lock of a never-synced welcome note stays local, the Model and Requirement say it is queued

## What happens

Quando l'utente mette il lucchetto a una nota di benvenuto mai sincronizzata, la nota cambia subito sul dispositivo, ma la modifica non entra nella coda per il cloud: resta solo sul dispositivo finché la sincronizzazione non decide il destino della nota (eliminata se il cloud ha già delle note, altrimenti inviata).

## What should happen

Il Model dell'accesso alla nota dice che, quando il lucchetto viene messo o tolto, la nota viene salvata anche in coda per la sincronizzazione, senza eccezioni, e il Requisito dell'accesso dice lo stesso. Ma il Model e il Requisito delle note e della sincronizzazione dicono che i salvataggi di una nota di benvenuto mai sincronizzata non entrano in coda.

## Fix options

### Scrivere l'eccezione delle note di benvenuto nell'accesso

Il Model dell'accesso e il suo Requisito dicono che, per una nota di benvenuto mai sincronizzata, il lucchetto non entra in coda, come per ogni altro salvataggio di quella nota. Il codice resta com'è e la sincronizzazione decide il destino della nota. Costo: poche righe di Model e una riga di Requisito; per l'utente non cambia nulla.

### Accodare anche il lucchetto delle note di benvenuto

Il lucchetto di una nota di benvenuto mai sincronizzata entra in coda come le altre modifiche, e la regola di scarto della sincronizzazione decide la nota come per il resto. Costo: la regola che esclude le note di benvenuto dalla coda va ristretta ai soli salvataggi di testo, e il Model e il Requisito della sincronizzazione vanno riscritti.

## Where in the code

lib/core/services/sync_service.dart (notifyNoteChanged, ritorno anticipato per le note di benvenuto mai sincronizzate); lib/core/state/notes_provider.dart (toggleLock)
