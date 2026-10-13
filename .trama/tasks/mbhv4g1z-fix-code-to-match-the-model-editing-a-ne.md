---
column: done
technical: false
refs:
  - sync-run/Idle
drift: rnxdm4fm
proposal: null
agent: false
created: 2026-10-12T11:27:34.869Z
finished: 2026-10-12T11:28:57.971Z
---
# Fix code to match the Model: Editing a never-synced welcome note starts a sync run, the Model does not say so

## What happens

Quando l'utente modifica una nota di benvenuto mai sincronizzata, la nota non entra in coda, ma la sincronizzazione parte lo stesso se un utente è connesso. Se il cloud ha già delle note, la sincronizzazione elimina subito la nota dal dispositivo, come conseguenza di una semplice modifica che non ha accodato nulla.

## What should happen

Nel Diagramma una sincronizzazione parte solo quando un cambiamento entra in coda, o quando l'utente la chiede, o all'avvio e all'accesso. Una modifica che non accoda nulla non deve avviarne una: la nota di benvenuto resta sul dispositivo finché un'altra sincronizzazione decide il suo destino. Il Model non prevede questo passaggio, quindi non può essere seguito così com'è.

## Chosen option

**Keep welcome-note edits from starting a run**

La modifica di una nota di benvenuto mai sincronizzata non avvia più la sincronizzazione. Il Diagramma resta quello attuale. La nota viene decisa alla prossima sincronizzazione, avviata da un'altra modifica, dall'avvio o dal pulsante. Costo: una nota di benvenuto modificata può restare sul dispositivo più a lungo prima di essere inviata o scartata.

## Where in the code

lib/core/services/sync_service.dart: notifyNoteChanged
