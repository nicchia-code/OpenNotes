---
column: done
technical: false
refs:
  - pending-change/Queued
  - realtime-channel/Listening
drift: t8hb6zv7
proposal: null
agent: false
created: 2026-10-12T14:20:57.146Z
finished: 2026-10-12T14:22:35.978Z
---
# Fix code to match the Model: Queued changes of a note deleted in the cloud are dropped at once, outside the sync run

## What happens

Quando il canale in tempo reale segnala che una nota è stata eliminata nel cloud, il sistema elimina la nota dal dispositivo e toglie subito dalla coda tutti i suoi cambiamenti ancora in attesa, sia i salvataggi sia le eliminazioni. Il cambiamento non viene inviato né scartato da una sincronizzazione.

## What should happen

Il Model fa uscire dalla coda un cambiamento solo con gli esiti della sincronizzazione: inviato, scartato perché il cloud ha una copia più recente, scartato perché il cloud non ha più una nota già sincronizzata, oppure tolto con il cambio di account. Alla ricezione di una nota eliminata nel cloud la coda non cambia: la nota sparisce dal dispositivo e il suo salvataggio in coda viene scartato dalla sincronizzazione successiva.

## Chosen option

**Leave the queue to the next sync run**

Il canale elimina solo la nota dal dispositivo e lascia i suoi cambiamenti in coda. La sincronizzazione successiva li scarta, perché il cloud non ha più la nota, come già prevede il Model. Il Model resta invariato. Costo: fino alla sincronizzazione la coda conserva cambiamenti di una nota che non esiste più; nessun altro effetto visibile, perché la nota non può essere modificata.

## Where in the code

lib/core/services/sync_service.dart: gestione dell'eliminazione ricevuta dal canale in tempo reale, che chiama la rimozione dei cambiamenti in coda della nota.
