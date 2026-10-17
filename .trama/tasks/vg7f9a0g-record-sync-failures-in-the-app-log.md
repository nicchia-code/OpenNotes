---
column: done
technical: false
refs:
  - sync-run/Running
  - requirements/rules#sync-run
drift: null
proposal: null
agent: false
created: 2026-10-17T17:21:40.742Z
finished: 2026-10-17T18:53:05.302Z
---
# Record sync failures in the app log

Ogni errore di un giro, e ogni caricamento o download di allegato che fallisce, viene annotato nel registro dell'app con il dettaglio tecnico, come richiedono i Requirements. Oggi questi errori finiscono solo nei messaggi di debug, che l'utente non può leggere, e la categoria mostrata nell'indicatore non lascia traccia.
