---
column: done
technical: false
refs:
  - note-editor/Open/user.NAVIGATE_BACK
  - requirements/rules#note-editor
drift: null
proposal: null
agent: false
created: 2026-10-17T18:18:04.156Z
finished: 2026-10-17T18:28:14.765Z
---
# Fix code to match the Model: Waiting edit lost when a fast back gesture closes the mobile editor

Sul mobile, quando l'utente torna all'elenco (pulsante Indietro, gesto o tasto di sistema) mentre una modifica di testo è ancora in attesa di essere consegnata, la modifica deve essere consegnata e salvata nella nota anche se la schermata esce prima che l'attesa di 300 ms scada. Oggi la modifica in attesa viene annullata quando la schermata viene smontata: se l'uscita dura meno dell'attesa, per esempio con un gesto di ritorno veloce, il testo digitato subito prima si perde senza avviso. Deve valere per ogni modo di tornare indietro. Sul desktop, invece, il cambio di nota e la chiusura dell'editor continuano a scartare la modifica in attesa, come dice il Model.
