---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#realtime-channel
proposal: null
task: y9b31bb4
origin: d3oq4nql
critical: false
option: 1
note: null
resolvedBy: hp4kwvga
created: 2026-10-17T11:55:36.330Z
---
# Realtime echo check compares update times, not revisions

## What happens

Il canale ignora l'eco e le modifiche già viste confrontando updated_at con la copia locale. Le righe del cloud hanno la colonna revision, ma il dispositivo non conserva nessuna revisione nota: una modifica con revisione già nota non può essere scartata per revisione.

## What should happen

Il Requirement rules#realtime-channel dice che una modifica con revisione minore o uguale alla revisione nota è ignorata, e che la revisione nota è memorizzata sul dispositivo.

## Fix options

### Usare lo storage locale della revisione

Lasciare il controllo per revisione allo storage locale del Task mhb28mt0, che memorizza la revisione di ogni nota e cartella; questo Task resta in doing finché non c'è.

### Memorizzare la revisione in questo Task

Aggiungere in questo Task la memorizzazione locale della revisione di ogni nota e cartella, e usarla per scartare le modifiche già viste; tocca lo storage locale del Task mhb28mt0.

### Confrontare per ora di modifica

Chiedere una Proposal che sostituisca il controllo per revisione con il confronto per ora di modifica già in uso, con i suoi limiti sull'eco.

## Where in the code

lib/core/services/sync_service.dart: applyRemoteNote (confronto updatedAt con la copia locale) e handleRemoteNoteChange.
