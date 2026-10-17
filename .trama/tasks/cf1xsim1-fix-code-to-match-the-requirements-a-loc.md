---
column: done
technical: false
refs:
  - pending-change/Queued
  - sync-run/Pulling
  - requirements/rules#pending-change
drift: null
proposal: null
agent: false
created: 2026-10-17T18:16:56.974Z
finished: 2026-10-17T18:54:49.360Z
---
# Fix code to match the Requirements: A local change queued by a full check does not ask for a sync run

Quando un controllo completo trova che la copia locale di una nota o di una cartella è più recente di quella del cloud, la mette in coda per l'invio, ma non chiede un nuovo giro: il cambiamento aspetta la sincronizzazione successiva, cioè il prossimo avvio, ritorno in primo piano o intervallo. Ogni accodamento, se un utente è connesso, deve chiedere subito una sincronizzazione senza attenderla: durante un giro in corso la richiesta va ricordata per il giro successivo, come le altre richieste. Fatto quando un cambiamento accodato durante la lettura del cloud parte nel giro successivo senza attendere l'intervallo.
