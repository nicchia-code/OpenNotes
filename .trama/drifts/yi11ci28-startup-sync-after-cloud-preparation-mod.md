---
status: resolved
resolution: fix-code
refs:
  - cloud-connection/Configuring/cloud-connection.CONFIGURED
proposal: null
task: i9fogfyr
origin: null
critical: false
option: 1
note: null
resolvedBy: 3mor38de
created: 2026-10-12T19:46:13.441Z
---
# Startup sync after cloud preparation: Model says ignored, code runs it

## What happens

Quando la preparazione del collegamento riesce e un utente risulta già connesso, l'app libera il segnale di occupato e chiede subito una sincronizzazione, che viene eseguita davvero. Al termine cartelle, tag ed elenco delle note vengono ricaricati. Il Model dice invece che quella richiesta viene ignorata perché il segnale di occupato è ancora attivo.

## What should happen

La sincronizzazione chiesta quando il collegamento diventa pronto deve essere ignorata, perché il segnale di occupato è ancora attivo in quel momento; l'elenco viene ricaricato solo alla fine della preparazione.

## Fix options

### Mantenere la sincronizzazione all'avvio

La sincronizzazione chiesta al collegamento pronto viene eseguita, come oggi, e il Model viene corretto: non dice più che è ignorata. Nessun cambio di codice; con un utente già connesso l'elenco si aggiorna subito dopo l'avvio.

### Ignorare la richiesta come nel Model

La richiesta di sincronizzazione al collegamento pronto viene scartata finché il segnale di occupato è attivo. Il codice cambia per non avviare la sincronizzazione in quel punto; le modifiche fatte su altri dispositivi arrivano solo alla sincronizzazione successiva, quindi l'elenco può restare indietro.

## Where in the code

lib/core/services/sync_service.dart, initializeSupabase
