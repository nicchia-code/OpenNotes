# Realtime channel

Il canale in tempo reale con cui il cloud avvisa l'app delle modifiche a note e cartelle dell'utente connesso, fatte da questo o da altri dispositivi. Le modifiche vengono applicate subito, anche durante una sincronizzazione completa.

## States

### Closed (initial)
Nessuna modifica remota viene ricevuta.
- `cloud-connection.CONFIGURED` → Listening: solo se un utente è già connesso.
- `supabase.INITIAL_SESSION` → Listening: solo se l'evento porta una sessione.
- `supabase.SIGNED_IN` → Listening: solo se l'evento porta una sessione.
- `supabase.TOKEN_REFRESHED` → Listening: solo se l'evento porta una sessione.

### Listening
Riceve le modifiche alle sole note e cartelle dell'utente connesso.
- `supabase.INITIAL_SESSION` → Listening: solo se l'evento porta una sessione; chiude il canale e ne apre uno nuovo.
- `supabase.SIGNED_IN` → Listening: solo se l'evento porta una sessione; chiude il canale e ne apre uno nuovo.
- `supabase.TOKEN_REFRESHED` → Listening: solo se l'evento porta una sessione; chiude il canale e ne apre uno nuovo.
- `supabase.REMOTE_NOTE_CHANGED` → Listening: se il dispositivo non ha la nota, oppure la sua copia non è stata modificata dopo quella del cloud, la versione del cloud la sostituisce e il suo file nel vault viene riscritto; altrimenti non succede nulla.
- `supabase.REMOTE_NOTE_DELETED` → Listening: elimina definitivamente la nota dal dispositivo, insieme al suo file nel vault se è noto.
- `supabase.REMOTE_FOLDER_CHANGED` → Listening: la cartella del cloud sovrascrive sempre quella locale.
- `supabase.REMOTE_FOLDER_DELETED` → Listening: elimina la cartella locale, salvo che sia di sistema, e sposta le sue note nella cartella "Note".
- `supabase.SIGNED_OUT` → Closed: chiude il canale; le note e cartelle locali restano.

## Events

### CLOUD_NOTE_APPLIED
Emesso quando una modifica remota crea o sostituisce la copia locale di una nota; l'app ricarica cartelle, tag ed elenco delle note.

### CLOUD_NOTE_REMOVED
Emesso quando una nota eliminata sul cloud viene eliminata definitivamente dal dispositivo; l'app ricarica cartelle, tag ed elenco delle note.
