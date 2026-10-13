---
status: resolved
resolution: dismissed
refs:
  - cloud-connection/Configuring/cloud-connection.CONFIGURED
proposal: null
task: null
origin: tvfz6d6q
critical: false
option: null
note: null
created: 2026-10-13T05:12:30.108Z
---
# Model still describes startup sync as ignored

## What happens

Quando il collegamento diventa pronto e un utente è già connesso, l'app apre il canale in tempo reale e avvia subito la sincronizzazione, come deciso nel Drift risolto. La descrizione del Model dice ancora che quella sincronizzazione viene ignorata.

## What should happen

Il Model deve descrivere la decisione presa: la sincronizzazione viene eseguita e, alla fine, cartelle, tag ed elenco delle note vengono ricaricati. Il Task chiede di correggere il Model, ma l'agente non può modificare il Model: serve una decisione del developer su come farlo.

## Fix options

### Correggere il Model con un Proposal approvato

Un Proposal che riscrive solo la descrizione di CONFIGURED, senza modificare il codice. La decisione passa dal developer prima che il Model cambi. Costo: un passaggio di approvazione in più prima di chiudere T7.

### Chiudere T7 lasciando il Model invariato

T7 si chiude senza modifiche né al codice né al Model, perché il codice è già quello deciso. Costo: il Model continua a dire che la sincronizzazione viene ignorata, in contrasto con il Drift risolto e con il comportamento reale.

## Where in the code

lib/core/services/sync_service.dart: initializeSupabase
