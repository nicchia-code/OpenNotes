---
column: done
technical: false
refs:
  - drawing-canvas/Saving/drawing-canvas.DRAWING_SAVE_FAILED
  - drawing-canvas/Drawing/user.SAVE_DRAWING
drift: null
proposal: null
agent: false
created: 2026-10-12T15:24:15.191Z
finished: 2026-10-12T16:32:33.334Z
---
# Fix code to match the Model: Drawing export error is not reported as a failed save

Quando il disegno non può essere esportato come immagine per un errore vero e proprio (non solo quando l'esportazione non produce dati), la tela deve comportarsi come per un salvataggio fallito: resta aperta con il disegno intatto e mostra il messaggio «Disegno non salvato», così l'utente può riprovare o annullare. Oggi un errore durante la conversione in immagine non viene gestito: nessun messaggio compare, la tela resta aperta senza alcuna spiegazione e l'utente non sa perché il disegno non è stato inserito.
