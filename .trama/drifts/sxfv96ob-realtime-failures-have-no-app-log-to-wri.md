---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#realtime-channel
proposal: null
task: bte7gp4l
origin: 4k2u3a3g
critical: false
option: 1
note: null
resolvedBy: 4bde0hn9
created: 2026-10-17T18:45:24.634Z
---
# Realtime failures have no app log to write to yet

## What happens

Quando una modifica ricevuta in tempo reale non si applica, il dettaglio dell'errore finisce solo nei messaggi di debug, che l'utente non può leggere. Il registro dell'app in cui annotarlo non esiste ancora: lo introduce il Task sgc92gr1 (che fissa i fallimenti di sincronizzazione e ancora in todo), da cui dipende il Task vg7f9a0g.

## What should happen

Il Requirement chiede che ogni errore di applicazione di una modifica in tempo reale venga annotato nel **registro dell'app**, come gli altri errori di sincronizzazione. Senza un registro non si può seguire, e costruirlo qui significherebbe fare il lavoro del Task sgc92gr1 e fissare in due posti il formato e la posizione del registro.

## Fix options

### Wait for the app log, then log realtime failures

Il Task resta in **doing** finché il Task sgc92gr1 non è in done. Poi l'errore di una modifica in tempo reale viene annotato nel registro dell'app, al posto del messaggio di debug; il giro incrementale che parte subito dopo e la prosecuzione della coda restano come sono. Costo: la correzione aspetta il lavoro precedente, ma non c'è codice duplicato.

### Build the app log inside this Task

Si crea qui il registro su file nella cartella documenti, come scelto per il Task sgc92gr1, e lo si usa per le modifiche in tempo reale. Costo: il registro nascerebbe in due Task diversi; il Task sgc92gr1 dovrà riusare e verificare il codice scritto qui, con il rischio di divergere su formato e tagli.

## Where in the code

lib/core/services/sync_service.dart: callback della coda delle modifiche in tempo reale (errore durante l'applicazione)
