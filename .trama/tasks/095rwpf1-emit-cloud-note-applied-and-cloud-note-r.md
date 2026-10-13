---
column: done
technical: false
refs:
  - realtime-channel.CLOUD_NOTE_APPLIED
  - realtime-channel.CLOUD_NOTE_REMOVED
  - realtime-channel/Listening/supabase.REMOTE_NOTE_CHANGED
  - realtime-channel/Listening/supabase.REMOTE_NOTE_DELETED
drift: null
proposal: null
agent: false
created: 2026-10-13T05:21:05.480Z
finished: 2026-10-13T05:36:17.887Z
---
# Emit CLOUD_NOTE_APPLIED and CLOUD_NOTE_REMOVED as distinct realtime events

Quando una modifica remota crea o sostituisce una nota, il canale emette CLOUD_NOTE_APPLIED; quando elimina una nota dal dispositivo, emette CLOUD_NOTE_REMOVED. Oggi entrambi i casi usano lo stesso segnale generico di ricarica delle liste, quindi chi ascolta non sa se la nota è stata rimossa o solo aggiornata. Fatto quando i due eventi sono distinti e ogni ascoltatore reagisce a quello che lo riguarda.
