---
status: resolved
resolution: fix-code
refs:
  - sync-run/Idle
proposal: null
task: mbhv4g1z
origin: null
critical: false
option: 1
note: null
resolvedBy: m16unv7j
created: 2026-10-12T11:22:38.040Z
---
# Editing a never-synced welcome note starts a sync run, the Model does not say so

## What happens

Quando l'utente modifica una nota di benvenuto mai sincronizzata, la nota non entra in coda, ma la sincronizzazione parte lo stesso se un utente è connesso. Se il cloud ha già delle note, la sincronizzazione elimina subito la nota dal dispositivo, come conseguenza di una semplice modifica che non ha accodato nulla.

## What should happen

Nel Diagramma una sincronizzazione parte solo quando un cambiamento entra in coda, o quando l'utente la chiede, o all'avvio e all'accesso. Una modifica che non accoda nulla non deve avviarne una: la nota di benvenuto resta sul dispositivo finché un'altra sincronizzazione decide il suo destino. Il Model non prevede questo passaggio, quindi non può essere seguito così com'è.

## Fix options

### Keep welcome-note edits from starting a run

La modifica di una nota di benvenuto mai sincronizzata non avvia più la sincronizzazione. Il Diagramma resta quello attuale. La nota viene decisa alla prossima sincronizzazione, avviata da un'altra modifica, dall'avvio o dal pulsante. Costo: una nota di benvenuto modificata può restare sul dispositivo più a lungo prima di essere inviata o scartata.

### Record the start in the Model

Il Diagramma della sincronizzazione dichiara che la modifica di una nota di benvenuto mai sincronizzata avvia una sincronizzazione. Il codice non cambia. Costo: una Proposal sulla sincronizzazione e sulla nota; la nota viene eliminata dal dispositivo subito dopo la modifica, se il cloud ha già note.

## Where in the code

lib/core/services/sync_service.dart: notifyNoteChanged
