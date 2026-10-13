---
column: done
technical: false
refs:
  - realtime-channel/Listening/supabase.REMOTE_NOTE_DELETED
  - realtime-channel/Listening/supabase.REMOTE_FOLDER_DELETED
  - requirements/rules#cloud-sync
drift: null
proposal: null
agent: false
created: 2026-10-12T10:45:47.119Z
finished: 2026-10-12T13:53:08.199Z
---
# Fix code to match the Model: Notes and folders deleted in the cloud never reach the device

Quando una nota o una cartella dell'utente connesso viene eliminata nel cloud (da questo o da un altro dispositivo), il dispositivo la rimuove subito mentre il canale è in ascolto: la nota con il suo file nel vault, la cartella con le note che passano a "Note" (la cartella di sistema non viene mai rimossa). Oggi le eliminazioni non arrivano mai: il canale è filtrato per utente, e il cloud non recapita le eliminazioni che passano per quel filtro senza l'identificativo completo della riga eliminata. A fine lavoro le eliminazioni di note e cartelle devono arrivare al dispositivo con il filtro per utente richiesto dai Requirements (la cui pubblicazione realtime è già attiva), senza accodare nulla nella coda di sincronizzazione.
