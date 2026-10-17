---
column: done
technical: false
refs:
  - note-access/Unlocked for session/sync-run.CLOUD_NOTE_APPLIED
  - note-access/Unlocked for session/realtime-channel.CLOUD_NOTE_APPLIED
  - note-access/Unprotected/sync-run.CLOUD_NOTE_APPLIED
  - note-access/Unprotected/realtime-channel.CLOUD_NOTE_APPLIED
  - requirements/data#note-access
drift: null
proposal: null
agent: false
created: 2026-10-17T12:12:33.376Z
finished: 2026-10-17T12:26:46.791Z
---
# Hide a note unlocked for the session when the cloud version protects it

Quando la versione arrivata dal cloud (sincronizzazione o tempo reale) rende protetta una nota, la nota deve tornare nascosta anche se era sbloccata per la sessione: al posto del contenuto compaiono l'avviso «Questa nota è protetta» e il pulsante «Visualizza nota», e lo sblocco di sessione di quella nota viene dimenticato, così che sia richiesto di nuovo il PIN. Oggi lo sblocco in memoria resta attivo e la nota resta visibile. Vale per le note che erano sbloccate e per quelle sbloccate in precedenza e poi tolte dalla protezione. Lo sblocco resta solo in memoria, come previsto dal Requisito.
