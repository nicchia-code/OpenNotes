---
column: done
technical: false
refs:
  - drawing-canvas/Saving/drawing-canvas.DRAWING_SAVE_FAILED
  - drawing-canvas/Pen
drift: null
proposal: null
agent: false
created: 2026-10-12T14:15:17.257Z
finished: 2026-10-12T16:27:20.089Z
---
# Fix code to match the Model: Failed save returns the canvas to the Pen tool

Quando il salvataggio del disegno fallisce, la tela deve tornare allo strumento penna, come dice il Model (il passaggio entra nello stato iniziale Pen). Oggi, se l'utente stava usando la gomma, la tela resta in modalità gomma. Restano invece da confermare come corretti il messaggio «Disegno non salvato», la tela aperta con il disegno intatto e la possibilità di riprovare. Va gestito anche il caso in cui l'esportazione dell'immagine fallisce con un errore: oggi in quel caso non compare alcun messaggio, mentre il Model vuole che ogni esportazione non riuscita porti a «Disegno non salvato».
