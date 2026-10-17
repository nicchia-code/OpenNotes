---
column: done
technical: false
refs:
  - sync-run/Pushing changes
drift: null
proposal: null
agent: false
created: 2026-10-17T12:50:11.020Z
finished: 2026-10-17T14:50:44.492Z
---
# Fix code to match the Model: Attachment upload failure stops the note send and fails the sync run

# Comportamento atteso
Un caricamento di immagine o disegno che il servizio di archiviazione rifiuta viene annotato nel registro dell'app, non ferma l'invio della nota e viene ritentato al giro successivo. Il giro non fallisce per un allegato non caricato: il Model riserva il fallimento del giro a rete, tempo scaduto, sessione scaduta ed errori imprevisti, e non agli allegati.

# Stato attuale
Il caricamento non intercetta l'errore: un rifiuto del servizio di archiviazione interrompe l'invio della nota e fa fallire il giro, che programma un nuovo tentativo. Il download degli allegati, invece, registra già l'errore e continua.

# Fatto quando
Un caricamento rifiutato lascia la nota inviata al cloud, il giro termina senza errore e l'allegato viene caricato nel giro successivo.
