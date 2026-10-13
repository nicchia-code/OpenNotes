# Supabase

Il servizio cloud facoltativo usato per l'accesso con Google e la sincronizzazione: comunica i cambi di sessione, riporta il browser all'app al termine dell'accesso e trasmette in tempo reale le modifiche fatte su altri dispositivi.

## Events

### REMOTE_FOLDER_DELETED
Il canale in tempo reale segnala che una cartella dell'utente è stata eliminata dal cloud.

### REMOTE_FOLDER_CHANGED
Il canale in tempo reale segnala che una cartella dell'utente è stata creata o modificata sul cloud.

### INITIAL_SESSION
All'avvio il servizio di autenticazione comunica la sessione iniziale, eventualmente conservata da un avvio precedente (o nessuna).

### SIGNED_IN
Il servizio di autenticazione comunica che un utente ha completato l'accesso.

### TOKEN_REFRESHED
Il servizio di autenticazione comunica il rinnovo del token della sessione.

### SIGNED_OUT
Il servizio di autenticazione comunica che la sessione è terminata (disconnessione o scadenza).

### OAUTH_REDIRECT_RECEIVED
Al termine dell'accesso Google nel browser, Supabase reindirizza il browser al ricevitore locale dell'app, con un codice, un token, un errore o nessuno di questi.

### REMOTE_NOTE_CHANGED
Il canale in tempo reale segnala che una nota dell'utente è stata creata o modificata sul cloud.

### REMOTE_NOTE_DELETED
Il canale in tempo reale segnala che una nota dell'utente è stata eliminata dal cloud.
