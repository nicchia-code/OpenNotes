---
column: done
technical: false
refs:
  - cloud-connection/Configuring/cloud-connection.CONFIGURED
drift: yi11ci28
proposal: null
agent: false
created: 2026-10-12T19:48:51.001Z
finished: 2026-10-12T19:50:21.231Z
---
# Fix code to match the Model: Startup sync after cloud preparation: Model says ignored, code runs it

## What happens

Quando la preparazione del collegamento riesce e un utente risulta già connesso, l'app libera il segnale di occupato e chiede subito una sincronizzazione, che viene eseguita davvero. Al termine cartelle, tag ed elenco delle note vengono ricaricati. Il Model dice invece che quella richiesta viene ignorata perché il segnale di occupato è ancora attivo.

## What should happen

La sincronizzazione chiesta quando il collegamento diventa pronto deve essere ignorata, perché il segnale di occupato è ancora attivo in quel momento; l'elenco viene ricaricato solo alla fine della preparazione.

## Chosen option

**Mantenere la sincronizzazione all'avvio**

La sincronizzazione chiesta al collegamento pronto viene eseguita, come oggi, e il Model viene corretto: non dice più che è ignorata. Nessun cambio di codice; con un utente già connesso l'elenco si aggiorna subito dopo l'avvio.

## Where in the code

lib/core/services/sync_service.dart, initializeSupabase
