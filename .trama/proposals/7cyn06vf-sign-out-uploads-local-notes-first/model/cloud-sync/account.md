# Account

L'account Google con cui l'utente accede al cloud. C'è al massimo una sessione per installazione; la sessione viene conservata dal servizio cloud tra un avvio e l'altro.

## States

### Signed out (initial)
Nessun utente connesso: le modifiche alle note restano in coda sul dispositivo.
- `supabase.INITIAL_SESSION` → Signed in: solo se esiste una sessione conservata da un avvio precedente.
- `user.SIGN_IN_WITH_GOOGLE` → Signed out: se il collegamento al cloud non è pronto; mostra l'errore "Supabase non è ancora configurato".
- `user.SIGN_IN_WITH_GOOGLE` → Signed out: se il browser non può essere aperto; mostra "Accesso Google non completato".
- `user.SIGN_IN_WITH_GOOGLE` → Awaiting login: negli altri casi. Su computer apre un ricevitore locale sulla porta 3000 della macchina, chiudendo quello di un tentativo precedente, e vi fa tornare il browser; se la porta non è disponibile, e sempre su telefono e tablet, il ritorno avviene tramite il collegamento dell'app. Apre il browser sulla pagina di accesso Google.

### Awaiting login
Il browser è aperto sull'accesso Google e l'app attende il ritorno. Appena il browser è aperto, la finestra delle impostazioni annuncia "Accesso completato! Sincronizzazione in corso...", chiede una sincronizzazione (ignorata, perché nessun utente è ancora connesso) e poi annuncia "Sincronizzazione completata con successo.".
- `user.SIGN_IN_WITH_GOOGLE` → Awaiting login: ricomincia il tentativo da capo, come dallo stato senza accesso.
- `supabase.OAUTH_REDIRECT_RECEIVED` → Signed in: se il ritorno porta un codice o un token e la sessione viene ottenuta; il browser mostra "Accesso completato con successo!" e prova a chiudere la scheda dopo 1,5 secondi; il ricevitore locale viene chiuso.
- `supabase.OAUTH_REDIRECT_RECEIVED` → Signed out: se il ritorno porta un codice o un token ma la sessione non si ottiene, oppure porta un errore; il browser mostra il messaggio di errore e il ricevitore locale viene chiuso.
- `supabase.OAUTH_REDIRECT_RECEIVED` → Awaiting login: se il ritorno non porta né codice, né token, né errore; il browser riceve una pagina che rimanda al ricevitore i parametri scritti dopo il cancelletto, oppure mostra "In attesa...". Il ricevitore resta aperto.
- `supabase.SIGNED_IN` → Signed in: il servizio cloud conferma l'accesso, per esempio dopo il ritorno tramite collegamento dell'app.

### Signed in
L'utente è connesso; la finestra delle impostazioni mostra la sua email e permette di sincronizzare o disconnettersi.
- `user.SIGN_OUT` → Signed out: prima carica sul cloud la coda dei cambiamenti e le note mai sincronizzate, mostrando "Caricamento delle note locali sul cloud..."; quando tutto è caricato chiude la sessione sul cloud. Le note locali restano sul dispositivo.
- `user.SIGN_OUT` → Signed in: se un cambiamento o una nota non può essere caricato, la disconnessione viene annullata: l'account resta connesso e la finestra mostra "Non è stato possibile caricare le note sul cloud: disconnessione annullata.".
- `supabase.SIGNED_OUT` → Signed out: la sessione termina per qualsiasi altro motivo.
