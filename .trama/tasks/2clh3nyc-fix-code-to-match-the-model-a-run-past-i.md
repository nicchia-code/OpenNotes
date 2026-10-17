---
column: done
technical: false
refs:
  - sync-run/Running
  - requirements/rules#sync-run
drift: null
proposal: null
agent: false
created: 2026-10-17T19:27:57.370Z
finished: 2026-10-17T19:40:54.607Z
---
# Fix code to match the Model: A run past its time limit fails during local steps too

Quando un giro supera il suo tempo massimo di due minuti, il giro fallisce con la categoria tempo scaduto anche se il tempo scade mentre il dispositivo applica cartelle e note già scaricate, senza che sia in corso una richiesta al cloud. Oggi il limite viene controllato solo prima di ogni richiesta al cloud e durante il download degli allegati: un giro può superare il limite, completarsi e aggiornare l'ora dell'ultima sincronizzazione. Fatto quando: un giro che supera il limite durante le fasi locali fallisce con tempo scaduto, passa in attesa di un nuovo tentativo e non aggiorna l'ora dell'ultima sincronizzazione.
