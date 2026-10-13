# Master PIN

Il PIN principale del dispositivo, unico per tutte le note protette, usato per sbloccarle, togliere loro il lucchetto e confermare le azioni sensibili su di esse.

## States

### Not set (initial)
Sul dispositivo non è salvato alcun PIN principale: ogni PIN inserito per sbloccare una nota risulta errato.
- `operating-system.APP_LAUNCHED` → Set: solo se sul dispositivo è già salvata l'impronta di un PIN principale.
- `user.LOCK_NOTE` → Set: si apre la richiesta di creazione del PIN; solo se l'utente inserisce un PIN di almeno quattro caratteri e lo ripete identico nella conferma, ne salva l'impronta sul dispositivo. Se il PIN è troppo corto o la conferma non coincide mostra un errore e la richiesta resta aperta; se l'utente annulla il PIN resta non impostato.

### Set
Il PIN principale è salvato sul dispositivo e viene confrontato con quello inserito ogni volta che serve. Non esiste un modo per cambiarlo o rimuoverlo dall'app; non viene mai sincronizzato con il cloud.
