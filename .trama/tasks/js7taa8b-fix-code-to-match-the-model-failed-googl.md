---
column: done
technical: false
refs:
  - account/Awaiting login/supabase.OAUTH_REDIRECT_RECEIVED
  - account/Signed out
drift: null
proposal: null
agent: false
created: 2026-10-12T11:38:55.331Z
finished: 2026-10-12T13:55:46.580Z
---
# Fix code to match the Model: Failed Google return leaves the app waiting for login

Quando il ritorno da Google porta un codice o un token ma la sessione non si ottiene, oppure porta un errore, il Model dice che l'app torna disconnessa (Signed out) e che il ricevitore locale si chiude. Oggi il ricevitore si chiude, ma l'app resta nello stato di attesa del ritorno: il flag che dice se l'app attende il browser non viene mai azzerato su questi percorsi. Di conseguenza un successivo evento di accesso confermato dal servizio cloud viene trattato come risposta a un accesso in corso, mentre dallo stato disconnesso il Model non prevede alcuna transizione. Correggere: su ogni ritorno che porta a disconnesso (errore sessione o errore dal provider) l'app deve uscire dall'attesa del ritorno, così che lo stato interno coincida con Signed out.
