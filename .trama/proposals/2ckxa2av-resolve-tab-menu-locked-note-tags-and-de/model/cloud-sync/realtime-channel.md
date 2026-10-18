# Realtime channel

Il canale in tempo reale con cui il cloud avvisa l'app delle modifiche a note e cartelle dell'utente connesso, fatte da questo o da altri dispositivi, eliminazioni comprese. Le modifiche vengono applicate subito, anche durante una sincronizzazione, in ordine di arrivo e una alla volta. Il canale non garantisce di consegnare tutto: quando si interrompe e si ricollega, o quando una modifica non si riesce ad applicare, chiede una sincronizzazione che recupera ciò che manca.

## States

### Closed (initial)
Nessuna modifica remota viene ricevuta.
- `cloud-connection.CONFIGURED` → Open: solo se un utente è già connesso.
- `supabase.INITIAL_SESSION` → Open: solo se l'evento porta una sessione.
- `supabase.SIGNED_IN` → Open: solo se l'evento porta una sessione.
- `supabase.TOKEN_REFRESHED` → Open: solo se l'evento porta una sessione.

### Open
Il canale è aperto per le sole note e cartelle dell'utente connesso. Al rinnovo del token di accesso il canale resta aperto e riceve il nuovo token, senza chiudersi.
- `supabase.INITIAL_SESSION` → Open: solo se l'evento porta una sessione; chiude il canale e ne apre uno nuovo.
- `supabase.SIGNED_IN` → Open: solo se l'evento porta una sessione; chiude il canale e ne apre uno nuovo.
- `supabase.SIGNED_OUT` → Closed: chiude il canale; le note e cartelle locali restano.

#### Listening (initial)
Il canale è collegato e riceve le modifiche. Per ogni modifica, se il dispositivo conosce già quella revisione o una successiva, come per l'eco dei propri invii, non succede nulla. Se la modifica non si riesce ad applicare, viene emesso CHANGE_NOT_APPLIED e il canale passa alla successiva.
- `supabase.REMOTE_NOTE_CHANGED` → Listening: se il dispositivo non ha una modifica in attesa della nota, in coda o messa da parte, successiva a quella del cloud, la versione del cloud sostituisce quella locale, il suo file nel vault viene riscritto, le modifiche in attesa più vecchie vengono scartate e il dispositivo ricorda la nuova revisione; le immagini e i disegni che mancano sul dispositivo vengono scaricati. Altrimenti resta la copia locale. Una nota applicata la cui cartella non esiste sul dispositivo va nella cartella "Note", senza cambiare la data di modifica.
- `supabase.REMOTE_NOTE_DELETED` → Listening: se il dispositivo non ha una modifica in attesa della nota successiva all'eliminazione, elimina definitivamente la nota dal dispositivo, insieme al suo file nel vault se è noto e nessun'altra nota lo usa, e scarta subito le sue modifiche in attesa, senza attendere la sincronizzazione; altrimenti resta la copia locale, che rinascerà sul cloud.
- `supabase.REMOTE_FOLDER_CHANGED` → Listening: se il dispositivo non ha una modifica in attesa della cartella successiva a quella del cloud, la cartella del cloud sostituisce quella locale e il dispositivo ricorda la nuova revisione; altrimenti resta la copia locale. Vale anche per una cartella eliminata qui la cui eliminazione è ancora in coda: se la versione del cloud non è più vecchia dell'eliminazione, l'eliminazione viene scartata e la cartella torna subito, senza attendere la sincronizzazione.
- `supabase.REMOTE_FOLDER_DELETED` → Listening: se il dispositivo non ha una modifica in attesa della cartella successiva all'eliminazione, elimina la cartella locale, salvo che sia di sistema, e sposta le sue note nella cartella "Note" senza accodarle; altrimenti resta la copia locale.
- `supabase.REALTIME_INTERRUPTED` → Interrupted

#### Interrupted
Il collegamento si è interrotto (errore, tempo scaduto, rete persa, app sospesa) e la libreria del cloud prova a ricollegarlo da sola; nel frattempo le modifiche fatte altrove non arrivano.
- `supabase.REALTIME_CONNECTED` → Listening: emette RECONNECTED.

## Events

### CLOUD_NOTE_APPLIED
Emesso quando una modifica remota crea o sostituisce la copia locale di una nota; l'app ricarica cartelle, tag ed elenco delle note.

### CLOUD_NOTE_REMOVED
Emesso quando una nota eliminata sul cloud viene eliminata definitivamente dal dispositivo; l'app ricarica cartelle, tag ed elenco delle note.

### RECONNECTED
Emesso quando il canale torna collegato dopo un'interruzione: parte una sincronizzazione che recupera le modifiche perse nel frattempo.

### CHANGE_NOT_APPLIED
Emesso quando una modifica ricevuta non si riesce ad applicare sul dispositivo: parte una sincronizzazione che la recupera.
