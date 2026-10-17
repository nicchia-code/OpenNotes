---
column: done
technical: false
refs:
  - sync-run/Pushing changes
  - requirements/rules#sync-run
drift: null
proposal: null
agent: false
created: 2026-10-17T19:27:58.637Z
finished: 2026-10-17T19:41:35.435Z
---
# Fix code to match the Requirements: Attachment retry of synced notes runs inside the fixed run order

L'ordine fisso di un giro è: verifica del cambio di account, invio della coda, lettura del cloud, invio delle note mai sincronizzate, applicazione delle cartelle, applicazione delle note, download degli allegati mancanti, e solo nel controllo completo rimozione delle righe locali assenti dal cloud. Oggi il giro carica le immagini e i disegni delle note già nel cloud che il cloud non ha, per ritentare i caricamenti falliti, in un passo che precede l'invio della coda e che l'ordine non prevede. Il ritentativo deve avvenire dentro il passo dell'invio della coda, così che l'ordine resti quello del Requirement e il caricamento fallito venga ritentato al giro successivo come oggi. Fatto quando: nessun caricamento di allegati precede la verifica del cambio di account e l'invio della coda, e i caricamenti di allegati di note già nel cloud vengono ritentati dentro l'invio della coda.
