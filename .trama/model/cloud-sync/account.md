# Account

L'account Google con cui l'utente accede al cloud. C'è al massimo una sessione per installazione; la sessione viene conservata dal servizio cloud tra un avvio e l'altro.

## States

### Signed out (initial)
Nessun utente connesso: le modifiche alle note e alle cartelle restano in coda sul dispositivo e l'indicatore della sincronizzazione non è mostrato.
- `supabase.INITIAL_SESSION` → Signed in: solo se esiste una sessione conservata da un avvio precedente.
- `supabase.SIGNED_IN` → Signed in: solo se l'evento porta una sessione, anche se l'app non stava attendendo il ritorno dal browser; come per ogni accesso, parte una sincronizzazione con controllo completo e si apre il canale in tempo reale.
- `user.SIGN_IN_WITH_GOOGLE` → Signed out: se il collegamento al cloud non è pronto; se la build non fornisce l'indirizzo o la chiave del progetto cloud mostra l'avviso di cloud non configurato, che nomina ciò che manca, altrimenti mostra l'errore "Supabase non è ancora configurato".
- `user.SIGN_IN_WITH_GOOGLE` → Signed out: se il browser non può essere aperto; mostra "Accesso Google non completato".
- `user.SIGN_IN_WITH_GOOGLE` → Signed out: se l'avvio dell'accesso fallisce per un altro errore imprevisto, per esempio del servizio cloud durante la preparazione; il ricevitore locale aperto per il tentativo viene chiuso, non resta alcuna attesa del ritorno e la finestra mostra "Accesso Google non completato".
- `user.SIGN_IN_WITH_GOOGLE` → Awaiting login: negli altri casi. Su computer apre un ricevitore locale sulla porta 3000 della macchina, chiudendo quello di un tentativo precedente, e vi fa tornare il browser; se la porta non è disponibile, e sempre su telefono e tablet, il ritorno avviene tramite il collegamento dell'app. Apre il browser sulla pagina di accesso Google.

### Awaiting login
Il browser è aperto sull'accesso Google e l'app attende il ritorno; intanto la finestra delle impostazioni continua a mostrare "Apertura browser per autenticazione Google...". Quando l'attesa finisce, se la finestra è ancora aperta: se l'utente è connesso annuncia "Accesso completato! Sincronizzazione in corso...", attende la vera fine della sincronizzazione avviata dall'accesso e poi annuncia "Sincronizzazione completata con successo."; se quella sincronizzazione fallisce mostra invece la categoria dell'errore e fra quanto avverrà il nuovo tentativo. Se l'utente non è connesso mostra "Accesso Google non completato.", oppure "Accesso non completato:" seguito dal messaggio se il ritorno tramite il collegamento dell'app ha portato un errore.
- `user.SIGN_IN_WITH_GOOGLE` → Awaiting login: ricomincia il tentativo da capo, come dallo stato senza accesso.
- `supabase.OAUTH_REDIRECT_RECEIVED` → Signed in: se il ritorno porta un codice o un token e la sessione viene ottenuta; il browser mostra "Accesso completato con successo!" e prova a chiudere la scheda dopo 1,5 secondi; il ricevitore locale viene chiuso.
- `supabase.OAUTH_REDIRECT_RECEIVED` → Signed out: se il ritorno porta un codice o un token ma la sessione non si ottiene, oppure porta un errore; il browser mostra il messaggio di errore e il ricevitore locale viene chiuso.
- `supabase.OAUTH_REDIRECT_RECEIVED` → Signed out: se il ritorno avviene tramite il collegamento dell'app e porta un errore, per esempio perché l'utente annulla l'accesso; la finestra delle impostazioni mostra "Accesso non completato:" seguito dal messaggio di errore, finché non parte un nuovo tentativo o l'accesso riesce.
- `supabase.OAUTH_REDIRECT_RECEIVED` → Awaiting login: se il ritorno non porta né codice, né token, né errore; il browser riceve una pagina che rimanda al ricevitore i parametri scritti dopo il cancelletto, oppure mostra "In attesa...". Il ricevitore resta aperto.
- `supabase.SIGNED_IN` → Signed in: il servizio cloud conferma l'accesso, per esempio dopo il ritorno tramite collegamento dell'app.

### Signed in
L'utente è connesso e l'app mostra l'indicatore della sincronizzazione. La finestra delle impostazioni mostra la sua email, lo stato della sincronizzazione, l'ora dell'ultima sincronizzazione, il numero di modifiche in attesa, l'ultimo errore con il prossimo tentativo e le note e cartelle non sincronizzate con le loro azioni, e permette di sincronizzare (con controllo completo) o disconnettersi.
- `user.SIGN_OUT` → Signed out: chiude la sessione sul cloud. Le note locali e la coda dei cambiamenti restano sul dispositivo.
- `supabase.SIGNED_OUT` → Signed out: la sessione termina per qualsiasi altro motivo.
