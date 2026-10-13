---
status: resolved
resolution: fix-code
refs:
  - sync-run/Idle
proposal: null
task: rd342in7
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:26:45.442Z
---
# App start does not wait for a sync already running

## What happens

All'avvio il collegamento viene preparato e, se un utente è connesso, parte una sincronizzazione. Se a quel punto ne è già in corso una, ad esempio quella avviata dall'accesso automatico, la richiesta dell'avvio viene scartata e l'avvio prosegue subito: decide se creare le note di benvenuto mentre la sincronizzazione non è ancora finita.

## What should happen

L'avvio attende la fine della sincronizzazione prima di decidere se creare le note di benvenuto. Le richieste che arrivano durante una sincronizzazione restano scartate, ma l'avvio non deve decidere prima che quella in corso finisca.

## Fix options

### Wait for the sync already running

Il servizio di sincronizzazione offre un'attesa sulla sincronizzazione in corso: l'avvio attende quella già partita e decide solo dopo. Le altre richieste restano scartate come ora. Costo: un metodo in più nel servizio e un avvio che dura di più quando il cloud è lento.

### Listen for the end of the sync before deciding

L'avvio ascolta la fine della sincronizzazione, anche quella già in corso, e decide le note di benvenuto solo dopo. Il servizio segnala la fine anche dopo un errore, quindi il caso è coperto. Costo: più codice nell'avvio e un segnale da gestire.

## Where in the code

lib/main.dart: avvio, chiamata di sincronizzazione e creazione delle note di benvenuto; lib/core/services/sync_service.dart: syncNow, uscita immediata se una sincronizzazione è in corso.
