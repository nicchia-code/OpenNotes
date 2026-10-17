---
column: done
technical: true
refs:
  - requirements/rules#realtime-channel
drift: sxfv96ob
proposal: null
agent: false
created: 2026-10-17T19:46:55.441Z
finished: 2026-10-17T19:48:08.664Z
---
# Fix code to match the Requirements: Realtime failures have no app log to write to yet

## What happens

Quando una modifica ricevuta in tempo reale non si applica, il dettaglio dell'errore finisce solo nei messaggi di debug, che l'utente non può leggere. Il registro dell'app in cui annotarlo non esiste ancora: lo introduce il Task sgc92gr1 (che fissa i fallimenti di sincronizzazione e ancora in todo), da cui dipende il Task vg7f9a0g.

## What should happen

Il Requirement chiede che ogni errore di applicazione di una modifica in tempo reale venga annotato nel **registro dell'app**, come gli altri errori di sincronizzazione. Senza un registro non si può seguire, e costruirlo qui significherebbe fare il lavoro del Task sgc92gr1 e fissare in due posti il formato e la posizione del registro.

## Chosen option

**Wait for the app log, then log realtime failures**

Il Task resta in **doing** finché il Task sgc92gr1 non è in done. Poi l'errore di una modifica in tempo reale viene annotato nel registro dell'app, al posto del messaggio di debug; il giro incrementale che parte subito dopo e la prosecuzione della coda restano come sono. Costo: la correzione aspetta il lavoro precedente, ma non c'è codice duplicato.

## Where in the code

lib/core/services/sync_service.dart: callback della coda delle modifiche in tempo reale (errore durante l'applicazione)
