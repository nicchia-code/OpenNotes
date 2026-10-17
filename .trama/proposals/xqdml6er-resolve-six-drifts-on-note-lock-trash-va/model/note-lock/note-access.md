# Note access

L'accesso al contenuto di una singola nota rispetto al lucchetto, durante una sessione dell'app, dall'avvio alla chiusura.

## States

### Unprotected (initial)
La nota non ha il lucchetto: contenuto e anteprima sono visibili e modificabili liberamente. Le copie di note protette e le note che arrivano già protette dalla sincronizzazione nascono invece con il lucchetto. Se l'utente annulla la creazione del PIN principale richiesta per proteggere la nota, la nota resta senza lucchetto.
- `user.LOCK_NOTE` → Locked: solo se il PIN principale è già impostato oppure l'utente lo crea nella richiesta che si apre; il PIN esistente non viene chiesto. La nota viene salvata con il lucchetto in locale, nel vault e in coda per la sincronizzazione, con la data di modifica aggiornata, e la sua anteprima diventa l'avviso di nota protetta.
- `sync-run.CLOUD_NOTE_APPLIED` → Locked: solo se la versione del cloud sostituisce quella locale ed è protetta; la nota viene nascosta anche sul dispositivo, senza che l'utente la blocchi.
- `realtime-channel.CLOUD_NOTE_APPLIED` → Locked: alle stesse condizioni del passaggio sopra.

### Protected
La nota ha il lucchetto. Nell'elenco restano visibili il titolo, la data, i tag e l'icona del lucchetto, mentre l'anteprima è sempre l'avviso di nota protetta, anche quando è sbloccata. Duplicare, condividere, esportare in Markdown ed eliminare definitivamente la nota chiedono ogni volta il PIN corretto, anche se la nota è sbloccata per la sessione; svuotare il cestino chiede il PIN se nel cestino ce n'è almeno una protetta. Fissare, spostare in un'altra cartella e spostare nel cestino non chiedono il PIN.
- `user.REMOVE_NOTE_LOCK` → Unprotected: solo se l'utente inserisce il PIN principale corretto nella richiesta che si apre, anche quando la nota è già sbloccata per la sessione. La nota viene salvata senza lucchetto in locale, nel vault e in coda per la sincronizzazione, con la data di modifica aggiornata, e l'anteprima torna a mostrare il contenuto. Con un PIN errato la richiesta mostra un errore e resta aperta; se l'utente annulla non cambia nulla.
- `sync-run.CLOUD_NOTE_APPLIED` → Unprotected: solo se la versione del cloud sostituisce quella locale ed è senza lucchetto; il lucchetto segue il cloud, quindi la nota si mostra senza PIN anche se era nascosta o sbloccata per la sessione.
- `realtime-channel.CLOUD_NOTE_APPLIED` → Unprotected: alle stesse condizioni del passaggio sopra.

#### Locked (initial)
Il contenuto è nascosto: al posto dell'editor compaiono l'avviso di nota protetta e il pulsante per visualizzarla.
- `user.VIEW_LOCKED_NOTE` → Unlocked for session: solo se l'utente inserisce il PIN principale corretto nella richiesta che si apre. Con un PIN errato la richiesta mostra un errore e resta aperta; un PIN vuoto viene ignorato; se l'utente annulla la nota resta nascosta.

#### Unlocked for session
Il contenuto è visibile e modificabile nell'editor fino alla chiusura dell'app. La nota non torna nascosta quando l'app va in secondo piano né quando l'utente passa a un'altra nota.
- `operating-system.APP_LAUNCHED` → Locked: alla successiva apertura dell'app la nota torna nascosta, perché gli sblocchi non vengono conservati tra una sessione e l'altra.
- `sync-run.CLOUD_NOTE_APPLIED` → Locked: solo se la versione del cloud sostituisce quella locale ed è protetta; la nota torna nascosta anche se era sbloccata per la sessione.
- `realtime-channel.CLOUD_NOTE_APPLIED` → Locked: alle stesse condizioni del passaggio sopra.

## Events

### UNLOCKED
Emesso quando la nota viene sbloccata per la sessione e il suo contenuto diventa visibile nell'editor.

### RELOCKED
Emesso quando il contenuto della nota torna nascosto: subito dopo che le è stato messo il lucchetto, oppure alla riapertura dell'app per una nota che era sbloccata.

### PROTECTION_REMOVED
Emesso quando alla nota viene tolto il lucchetto e il contenuto torna visibile a tutti gli effetti.
