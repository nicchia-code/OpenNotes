---
column: done
technical: false
refs:
  - account/Signed out
  - account/Awaiting login/supabase.OAUTH_REDIRECT_RECEIVED
drift: null
proposal: null
agent: false
created: 2026-10-12T11:38:55.541Z
finished: 2026-10-12T14:00:43.924Z
---
# Fix code to match the Model: Local return server stays open after the browser fails to open

Il Model colloca il ricevitore locale sulla porta 3000 solo nello stato Awaiting login: lo apre il tentativo di accesso e lo chiude il ritorno con esito (successo o errore). Quando il browser non può essere aperto, l'app torna disconnessa (Signed out) con il messaggio 'Accesso Google non completato', ma il ricevitore resta in ascolto sulla porta 3000. Lo stesso accade se l'apertura dell'accesso Google fallisce con un'eccezione. Il Model in Signed out non ha alcuna transizione di ritorno dal browser, quindi un ritorno tardivo non va accettato. Correggere: sia nel caso di browser non aperto sia in quello di eccezione, il ricevitore locale va chiuso prima di tornare disconnessi, così che lo stato Signed out non lasci la porta occupata né accetti un ritorno.
