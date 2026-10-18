---
status: resolved
resolution: proposal
refs:
  - pending-change/Queued
proposal: null
task: null
origin: null
previous: mzj6nlf1
critical: false
option: null
note: null
resolvedBy: famz2y49
created: 2026-10-18T18:29:14.992Z
---
# Salvataggio in coda di una nota di benvenuto tolto senza invio: il Model non lo dice

## What happens

Un salvataggio già in coda di una nota mai sincronizzata, che prende un titolo di benvenuto, viene tolto dalla coda senza essere inviato, quando la coda viene inviata: il codice lo fa in _sendQueuedNote. La decisione passa alla sincronizzazione, che elimina la nota se il cloud ha già altre note oppure la invia con il testo attuale. Il Model della coda non ha alcuna uscita per questo scarto.

## What should happen

Il Model della coda deve dire che un salvataggio in coda di una nota mai sincronizzata con titolo di benvenuto viene tolto senza essere inviato, e che la decisione passa alla sincronizzazione, come già deciso nel Drift mzj6nlf1 e come chiede il Requirement sulle note di benvenuto.

## Fix options

### Scrivere lo scarto nel Model

Aggiungere al Model della coda l'uscita Discarded per il salvataggio di una nota di benvenuto mai sincronizzata, con il rinvio alla sincronizzazione. Il codice resta com'è.

### Inviare il testo attuale

Aggiornare il salvataggio in coda con il testo corrente quando la nota prende un titolo di benvenuto, così ogni salvataggio in coda viene inviato. La nota arriverebbe al cloud anche quando il cloud ha già altre note, e la regola di eliminazione delle note di benvenuto non varrebbe più per loro.

## Where in the code

lib/core/services/sync_service.dart: _sendQueuedNote, ramo delle note di benvenuto mai sincronizzate
