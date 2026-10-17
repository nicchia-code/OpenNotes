---
status: resolved
resolution: fix-code
refs:
  - sync-run/Sending unsynced notes
  - requirements/rules#sync-run
proposal: null
task: inr9ealt
origin: null
critical: false
option: 3
note: null
resolvedBy: hmikgd4m
created: 2026-10-17T18:17:28.366Z
---
# A note refused by the cloud during the unsynced sweep fails the whole sync run

## What happens

Le note mai sincronizzate senza una modifica in coda, come le note di benvenuto o quelle presenti già prima dell'aggiornamento, vengono inviate direttamente. Se il cloud rifiuta una di queste note, il giro si interrompe con un errore imprevisto e non legge né scarica nulla dal cloud. Il giro successivo riparte dallo stesso punto e fallisce di nuovo: finché il cloud rifiuta la nota, nessuna nota del cloud arriva sul dispositivo.

## What should happen

Secondo i Requirements un cambiamento rifiutato dal cloud (una risposta 4xx diversa da 401, 408 e 429, oppure un errore del database per vincolo, dato non valido o permesso) **non fa fallire il giro**: il giro prosegue con le altre parti. Anche il Model dice che il giro fallisce per rete, tempo scaduto, sessione o errore imprevisto, non per un cambiamento rifiutato dal cloud.

## Fix options

### Lasciare la nota non sincronizzata e proseguire il giro

Un rifiuto durante l'invio delle note mai sincronizzate viene annotato, la nota resta sul dispositivo come non sincronizzata e il giro prosegue con cartelle e note. La nota viene riprovata a ogni giro, senza essere messa da parte. Costo: una richiesta rifiutata a ogni giro finché il cloud non accetta la nota, e l'utente non vede quale nota blocca l'invio se non nel registro dell'app, che ancora non esiste.

### Mettere da parte la nota rifiutata come le modifiche in coda

Il rifiuto viene contato per la nota come per le modifiche in coda: dopo tre rifiuti di fila la nota viene messa da parte, non è più inviata, e compare tra le modifiche messe da parte nelle impostazioni del cloud, con il pulsante Riprova. Costo: il conteggio dei rifiuti va tenuto anche per le note senza coda, e la finestra del cloud mostra anche queste note.

### Accodare le note mai sincronizzate prima dell'invio

Prima di inviare una nota mai sincronizzata senza modifica in coda, la si mette in coda. Il suo eventuale rifiuto segue la stessa strada di ogni modifica in coda, con i tre rifiuti e la messa da parte. La decisione sulle note di benvenuto resta quella dell'invio, quindi non cambia il fatto che non entrano in coda al salvataggio. Costo: una scrittura in più per ogni nota da inviare e più casi da coprire nella coda.

## Where in the code

lib/core/services/sync_service.dart: _sendUnsyncedNote invia senza catturare i rifiuti; _pushQueue conta già i rifiuti delle modifiche in coda e il giro prosegue; _runOnce fa fallire il giro per ogni errore non riconosciuto come rete, tempo o sessione.
