---
status: resolved
resolution: fix-code
refs:
  - sync-run/Running
  - requirements/rules#sync-run
proposal: null
task: 3pb9l752
origin: null
critical: false
option: 1
note: null
resolvedBy: hmikgd4m
created: 2026-10-17T18:17:33.797Z
---
# A connection dropped during a cloud answer is reported as an unexpected error

## What happens

Quando la connessione si interrompe mentre il cloud risponde, per esempio a metà di una risposta, il giro fallisce ma l'app mostra Errore imprevisto invece di Rete non raggiungibile. Solo i guasti di socket vengono riconosciuti come rete; l'interruzione che arriva come errore del client HTTP durante la risposta resta imprevista.

## What should happen

Secondo i Requirements una connessione interrotta è un errore di rete: il giro fallisce con la categoria rete e l'app mostra Rete non raggiungibile. Il tentativo successivo non cambia: cambia solo il messaggio che l'utente vede e la categoria registrata.

## Fix options

### Riconoscere come rete ogni errore di trasporto del client HTTP

La classificazione dei fallimenti riconosce come rete anche l'errore di trasporto del client HTTP, oltre agli errori di socket. È una modifica di una sola funzione e copre le interruzioni che oggi cadono in imprevisto. Costo: un errore di trasporto che non dipende dalla rete, se mai ce ne fosse, verrebbe mostrato come rete.

### Avvolgere le richieste al cloud in un errore di rete dell'app

Il punto unico in cui il giro chiama il cloud converte ogni errore di trasporto in un errore di rete dell'app, prima che arrivi alla classificazione; la classificazione resta quella di oggi. Costo: un tipo di errore in più da mantenere e un passaggio in più a ogni richiesta, anche a quelle che non falliscono.

### Riconoscere la rete dal testo dell'errore

La classificazione legge il messaggio dell'errore e cerca i testi tipici di una connessione chiusa. Non cambia i tipi di errore né le richieste. Costo: il testo dipende dalla libreria e dal sistema, quindi la categoria può cambiare senza che il codice cambi, e la corrispondenza va tenuta aggiornata.

## Where in the code

lib/core/services/sync_service.dart: syncErrorCategoryOf riconosce SocketException e HttpException di dart:io, ma non l'eccezione ClientException del pacchetto http, che il client HTTP usa per le interruzioni durante una risposta; la categoria finisce in _runOnce.
