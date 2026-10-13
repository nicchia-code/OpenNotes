# Sync run

Una sincronizzazione completa e bidirezionale tra note e cartelle del dispositivo e quelle dell'utente connesso sul cloud. Ne gira al massimo una alla volta: le richieste che arrivano mentre una è in corso, o mentre il collegamento al cloud viene preparato, vengono ignorate senza essere ripetute. Ogni avvio richiede il collegamento pronto e un utente connesso.

## States

### Idle (initial)
Nessuna sincronizzazione in corso.
- `operating-system.APP_LAUNCHED` → Running: solo se, dopo la preparazione del collegamento, un utente risulta connesso; l'avvio dell'app attende la fine della sincronizzazione prima di decidere se creare le note di benvenuto.
- `supabase.INITIAL_SESSION` → Running: solo se l'evento porta una sessione.
- `supabase.SIGNED_IN` → Running: solo se l'evento porta una sessione.
- `supabase.TOKEN_REFRESHED` → Running: solo se l'evento porta una sessione.
- `user.SYNC_NOW` → Running: l'utente connesso preme "Sincronizza Adesso".
- `pending-change.QUEUED` → Running: solo se un utente è connesso; chi ha accodato il cambiamento non attende la fine.

### Running
L'app segnala che una sincronizzazione è in corso. Ogni riga inviata al cloud viene assegnata all'utente connesso.
- `FAILED` → Idle: al primo errore la sincronizzazione si interrompe; l'errore viene solo annotato nel registro dell'app, l'utente non lo vede e l'ora dell'ultima sincronizzazione non cambia. Ciò che era già stato fatto resta fatto.

#### Pushing changes (initial)
Prima confronta l'utente connesso con l'ultimo che ha sincronizzato il dispositivo: se è un altro utente, elimina definitivamente dal dispositivo le note già sincronizzate, cestinate e protette comprese, insieme al loro file nel vault e senza accodare nulla, e da allora ricorda il nuovo utente; le note mai sincronizzate restano. Se il dispositivo non ricorda nessun utente, ricorda quello connesso senza eliminare nulla. Poi invia al cloud i cambiamenti in coda, dal più vecchio al più recente: per un salvataggio invia la nota intera, per un'eliminazione cancella la nota sul cloud. Ogni cambiamento viene tolto dalla coda solo dopo che il cloud lo ha accettato.
- `QUEUE_SENT` → Reading cloud

#### Reading cloud
Legge dal cloud tutte le note dell'utente, cestinate comprese, e tutte le sue cartelle.
- `CLOUD_READ` → Sending unsynced notes

#### Sending unsynced notes
Esamina ogni nota del dispositivo, cestinate comprese, che non è mai stata sincronizzata. Se il cloud ha almeno una nota e la nota ha esattamente il titolo di una delle due note di benvenuto, la elimina definitivamente dal dispositivo insieme al suo file nel vault; altrimenti la invia al cloud e la segna come sincronizzata in quel momento.
- `UNSYNCED_NOTES_SENT` → Pulling

#### Pulling
Per ogni nota del cloud: se il dispositivo non la ha, oppure la sua copia locale non è stata modificata dopo quella del cloud, la versione del cloud sostituisce quella locale e il suo file nel vault viene riscritto; altrimenti resta la copia locale. Ogni cartella del cloud sovrascrive sempre quella locale. Note e cartelle presenti solo sul dispositivo non vengono toccate.
- `COMPLETED` → Idle: registra l'ora dell'ultima sincronizzazione.

## Events

### CHANGE_SENT
Emesso per ogni cambiamento in coda che il cloud ha accettato.

### QUEUE_SENT
Emesso quando tutta la coda è stata inviata.

### CLOUD_READ
Emesso quando note e cartelle del cloud sono state lette.

### SAMPLE_NOTE_DISCARDED
Emesso per ogni nota di benvenuto mai sincronizzata che viene eliminata definitivamente dal dispositivo perché il cloud ha già delle note.

### PREVIOUS_ACCOUNT_NOTE_REMOVED
Emesso per ogni nota già sincronizzata che viene eliminata definitivamente dal dispositivo perché l'utente connesso è diverso dall'ultimo che ha sincronizzato il dispositivo.

### UNSYNCED_NOTES_SENT
Emesso quando tutte le note mai sincronizzate sono state inviate o scartate.

### CLOUD_NOTE_APPLIED
Emesso per ogni nota del cloud che crea o sostituisce la copia locale.

### COMPLETED
Emesso quando anche le cartelle del cloud sono state applicate.

### FAILED
Emesso al primo errore in qualsiasi passo.

### FINISHED
Emesso a ogni ritorno a riposo, dopo un completamento o un errore: l'app ricarica allora cartelle, tag ed elenco delle note.
