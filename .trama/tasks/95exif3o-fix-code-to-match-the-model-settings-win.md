---
column: done
technical: false
refs:
  - account/Awaiting login
drift: null
proposal: null
agent: false
created: 2026-10-17T12:46:03.161Z
finished: 2026-10-17T13:47:17.706Z
---
# Fix code to match the Model: Settings window waits forever after a failed local return

Quando il ritorno da Google arriva sul ricevitore locale con un errore, oppure porta un codice o un token ma la sessione non si ottiene, l'app esce dall'attesa del ritorno e torna senza accesso. La finestra delle impostazioni deve allora mostrare «Accesso Google non completato.» al posto di «Apertura browser per autenticazione Google...», e il pulsante di accesso deve tornare attivo. Oggi l'uscita dall'attesa su questi percorsi non avvisa la finestra, che resta sul messaggio di apertura del browser con il pulsante disattivato finché un altro cambiamento dello stato di sincronizzazione non la aggiorna.
