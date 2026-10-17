---
column: done
technical: false
refs:
  - sync-run/Running
  - requirements/rules#sync-run
drift: f2g32s8g
proposal: null
agent: false
created: 2026-10-17T18:38:45.639Z
finished: 2026-10-17T19:15:21.196Z
---
# Fix code to match the Model: A connection dropped during a cloud answer is reported as an unexpected error

## What happens

Quando la connessione si interrompe mentre il cloud risponde, per esempio a metà di una risposta, il giro fallisce ma l'app mostra Errore imprevisto invece di Rete non raggiungibile. Solo i guasti di socket vengono riconosciuti come rete; l'interruzione che arriva come errore del client HTTP durante la risposta resta imprevista.

## What should happen

Secondo i Requirements una connessione interrotta è un errore di rete: il giro fallisce con la categoria rete e l'app mostra Rete non raggiungibile. Il tentativo successivo non cambia: cambia solo il messaggio che l'utente vede e la categoria registrata.

## Chosen option

**Riconoscere come rete ogni errore di trasporto del client HTTP**

La classificazione dei fallimenti riconosce come rete anche l'errore di trasporto del client HTTP, oltre agli errori di socket. È una modifica di una sola funzione e copre le interruzioni che oggi cadono in imprevisto. Costo: un errore di trasporto che non dipende dalla rete, se mai ce ne fosse, verrebbe mostrato come rete.

## Where in the code

lib/core/services/sync_service.dart: syncErrorCategoryOf riconosce SocketException e HttpException di dart:io, ma non l'eccezione ClientException del pacchetto http, che il client HTTP usa per le interruzioni durante una risposta; la categoria finisce in _runOnce.
