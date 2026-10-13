---
column: done
technical: false
refs:
  - sync-run/Reading cloud
  - sync-run/Sending unsynced notes
  - requirements/rules#sync-run
drift: null
proposal: null
agent: false
created: 2026-10-12T15:08:41.779Z
finished: 2026-10-12T16:27:39.193Z
---
# Fix code to match the Model: Reading cloud stops at the first server page

Leggere dal cloud deve restituire tutte le note dell'utente, cestinate comprese, e tutte le sue cartelle, anche quando sono più di quante il server ne consegna in una sola risposta. Oggi la lettura prende solo la prima pagina del server (di norma 1000 righe): con più note, quelle oltre il limite non vengono scaricate né contate per decidere se il cloud ha già note di benvenuto. Va letto l'intero elenco a pagine.
