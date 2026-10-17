---
column: done
technical: false
refs:
  - sync-run/Waiting to retry
  - sync-run/Offline
drift: eriwydo7
proposal: null
agent: false
created: 2026-10-17T18:07:16.492Z
finished: 2026-10-17T18:52:04.783Z
---
# Fix code to match the Model: Full check owed by a cancelled retry is lost when the network drops

## What happens

Un giro completo fallisce e l'app programma il nuovo tentativo, che sarebbe anch'esso un controllo completo. Se la rete cade mentre si aspetta quel tentativo, il tentativo viene annullato e il controllo completo dovuto sparisce: quando la rete torna parte un giro incrementale. Dopo il primo giro del dispositivo, un controllo completo perso non viene più rifatto finché qualcuno non lo chiede a mano o accede di nuovo, quindi le cancellazioni fatte altrove durante la caduta restano sul dispositivo. Se invece la rete cade mentre il giro è in corso, il controllo completo viene ricordato per il ritorno della rete.

## What should happen

Il Model dice che il tentativo dopo un giro fallito è un controllo completo se lo era il giro fallito. Dice anche che, quando la rete cade durante un giro, il controllo completo in corso o richiesto viene ricordato per il ritorno della rete. Per la caduta di rete mentre si attende il tentativo dice solo che il tentativo viene annullato, senza dire se il controllo completo dovuto resta; il ritorno della rete parte completo solo se ne era stato ricordato uno.

## Chosen option

**Ricordare il controllo completo dovuto**

Quando la rete cade mentre si attende un tentativo di controllo completo, quel controllo completo resta richiesto e parte al ritorno della rete, come già avviene se la rete cade durante il giro. Il ritorno della rete fa così un controllo completo anche dopo un'attesa annullata. Costo: dopo una caduta di rete il primo giro è più lento e legge tutte le note e le cartelle; la coda non cambia.

## Where in the code

lib/core/services/sync_service.dart: il ramo del segnale di rete (networkAvailable) e la gestione di _retryFull e _fullOnNetwork in _runOnce e _start; lib/core/services/sync_triggers.dart: _setOnline, che annulla il tentativo programmato quando la rete cade.
