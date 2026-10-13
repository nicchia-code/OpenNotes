---
column: done
technical: false
refs:
  - sync-run/Pulling
  - note/Active/sync-run.CLOUD_NOTE_APPLIED
  - note-editor/Open/sync-run.CLOUD_NOTE_APPLIED
drift: null
proposal: null
agent: false
created: 2026-10-12T10:47:50.323Z
finished: 2026-10-12T13:55:53.513Z
---
# Fix code to match the Model: Cloud notes applied during a full sync reach the lists only at the end

Durante una sincronizzazione completa, ogni nota del cloud che crea o sostituisce la copia locale deve essere comunicata subito: l'elenco delle note, le cartelle e i tag si aggiornano mentre la sincronizzazione prosegue, e una nota aperta nell'editor mostra la versione arrivata dal cloud, come già accade per le modifiche in tempo reale. Oggi la copia locale viene scritta durante il download senza avvisare la schermata: l'aggiornamento arriva solo alla fine della sincronizzazione.
