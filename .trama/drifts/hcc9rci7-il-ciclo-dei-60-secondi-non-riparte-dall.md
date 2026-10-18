---
status: resolved
resolution: fix-code
refs:
  - sync-run
  - requirements/rules#sync-run
proposal: null
task: fo8mqkgc
origin: null
critical: false
option: 1
note: null
resolvedBy: oz8usosn
created: 2026-10-18T16:43:05.278Z
---
# Il ciclo dei 60 secondi non riparte dalla fine dell'ultimo giro

## What happens

Dopo un giro completato parte il conto dei 60 secondi della sincronizzazione periodica. Se nel frattempo parte un altro giro, per esempio per una modifica in coda, il conto precedente non viene annullato: scatta mentre il giro nuovo è ancora in corso e chiede un giro in più subito dopo.

## What should happen

Il conto dei 60 secondi deve ripartire solo dalla fine dell'ultimo giro. Un giro che parte nel frattempo deve annullare il conto precedente, così da non far scattare giri extra né anticipare la sincronizzazione periodica.

## Fix options

### Annullare il conto ad ogni avvio di giro

Il conto precedente viene annullato quando parte un giro e riparte solo quando quel giro finisce. La sincronizzazione periodica resta a 60 secondi dalla fine dell'ultimo giro, come chiede il Requirement, e non crea giri extra.

### Lasciare il conto così com'è

Il conto precedente continua a scorrere anche durante un giro più recente. Il comportamento resta quello di oggi: può partire un giro extra subito dopo quello in corso, e la sincronizzazione periodica può avvenire prima dei 60 secondi dalla fine dell'ultimo giro.

## Where in the code

lib/core/services/sync_service.dart: _runLoop (armInterval in finally), _start (nessun cancelInterval all'avvio del giro); lib/core/services/sync_triggers.dart: armInterval (riga 78), cancelInterval (riga 86), scheduleRetry (riga 93).
