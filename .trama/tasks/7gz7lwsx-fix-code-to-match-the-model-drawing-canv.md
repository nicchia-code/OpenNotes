---
column: done
technical: false
refs:
  - drawing-canvas/Saving
  - drawing-canvas/Drawing/user.CANCEL_DRAWING
drift: null
proposal: null
agent: false
created: 2026-10-12T14:47:17.239Z
finished: 2026-10-12T16:30:50.323Z
---
# Fix code to match the Model: Drawing canvas accepts edits and Annulla while saving

Mentre il disegno viene esportato e salvato (stato Saving) la tela resta visibile e non accetta altre azioni, tranne il tocco su «Fine», già gestito. Oggi invece nel codice la tela accetta ancora tratti, gomma, colori, annulla e cancella tutto, e il pulsante «Annulla» (come il ritorno indietro) chiude la tela anche mentre il salvataggio è in corso. Così il disegno può entrare comunque nella nota dopo che l'utente ha annullato, oppure i tratti aggiunti durante il salvataggio finiscono fuori dall'immagine senza avviso. Quando il lavoro è finito: durante il salvataggio il disegno e gli strumenti non cambiano, e «Annulla» non chiude la tela; la chiusura avviene solo con l'esito del salvataggio (DRAWING_SAVED) o con il ritorno allo stato Drawing in caso di errore.
