---
status: resolved
resolution: dismissed
refs:
  - cloud-connection/Configuring
  - cloud-connection.CONFIGURED
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: null
created: 2026-10-12T18:40:15.320Z
---
# Startup sync runs when the connection is ready, the Model says the request is ignored

## What happens

Quando il collegamento è pronto e un utente risulta già connesso, l'app **avvia subito** la sincronizzazione completa. Prima di farlo toglie il segnale di occupato, così la richiesta non viene scartata; l'elenco di cartelle, tag e note si ricarica alla fine di quella sincronizzazione.

## What should happen

Il Model dice che, nello stesso momento, la sincronizzazione richiesta **viene ignorata** perché il segnale di occupato è ancora attivo. La sincronizzazione di avvio è affidata alla Machine di sincronizzazione all'avvio, che parte dopo la preparazione e aspetta la fine prima di creare le note di benvenuto.

## Fix options

### Keep the sync here and correct the Model

Il comportamento resta com'è: appena il collegamento è pronto e c'è un utente connesso parte la sincronizzazione completa, e l'avvio aspetta che finisca. Si aggiorna il Model perché descriva questo invece di dire che la richiesta viene ignorata. Costo: una modifica al testo del Model; ciò che vede l'utente non cambia.

### Ignore the request as the Model says

La richiesta fatta quando il collegamento diventa pronto non parte; la sincronizzazione di avvio viene avviata dal percorso di avvio dell'app, dopo la preparazione, e l'avvio aspetta che finisca. Costo: il passaggio di consegna tra preparazione e sincronizzazione va riscritto e il segnale di occupato va gestito con più attenzione, con rischio di sincronizzazione mancata o doppia.

## Where in the code

lib/core/services/sync_service.dart: initializeSupabase, prima di syncNow() (_isSyncing = false)
