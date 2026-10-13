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
- `FAILED` → Idle: al primo errore la sincronizzazione si interrompe, tranne quando non si riesce a scaricare un allegato (vedi Pulling); l'errore viene solo annotato nel registro dell'app, l'utente non lo vede e l'ora dell'ultima sincronizzazione non cambia. Ciò che era già stato fatto resta fatto.

#### Pushing changes (initial)
Prima confronta l'utente connesso con l'ultimo che ha sincronizzato il dispositivo: se è un altro utente, elimina definitivamente dal dispositivo le note già sincronizzate, cestinate e protette comprese, insieme al loro file nel vault e senza accodare nulla, e scarta i loro cambiamenti ancora in coda; da allora ricorda il nuovo utente; le note mai sincronizzate restano. Se il dispositivo non ricorda nessun utente, ricorda quello connesso senza eliminare nulla. Poi invia al cloud i cambiamenti in coda, dal più vecchio al più recente, e toglie ciascuno dalla coda appena è stato inviato o scartato:
- salvataggio di una nota: se il cloud ha la nota e la sua copia non è più vecchia del salvataggio, il salvataggio viene scartato e la versione del cloud arriverà con il download; se il cloud non ha la nota ma il dispositivo l'aveva già sincronizzata, la nota è stata eliminata altrove: il salvataggio viene scartato e la nota viene eliminata definitivamente dal dispositivo, insieme al suo file nel vault; altrimenti invia la nota intera;
- eliminazione di una nota: se la nota del cloud è stata modificata dopo il momento in cui l'eliminazione è entrata in coda, l'eliminazione viene scartata e la nota torna sul dispositivo con il download; altrimenti cancella la nota sul cloud;
- creazione o rinomina di una cartella: invia la cartella, che sovrascrive quella del cloud senza confronto di date;
- eliminazione di una cartella: se la cartella del cloud è stata modificata dopo il momento in cui l'eliminazione è entrata in coda, l'eliminazione viene scartata e la cartella torna con il download; altrimenti cancella la cartella sul cloud, le cui sottocartelle diventano di primo livello.
- `QUEUE_SENT` → Reading cloud

#### Reading cloud
Legge dal cloud tutte le note dell'utente, cestinate comprese, e tutte le sue cartelle.
- `CLOUD_READ` → Sending unsynced notes

#### Sending unsynced notes
Esamina ogni nota del dispositivo, cestinate comprese, che non è mai stata sincronizzata. Se il cloud ha almeno una nota e la nota ha esattamente il titolo di una delle due note di benvenuto, la elimina definitivamente dal dispositivo insieme al suo file nel vault; altrimenti la invia al cloud e la segna come sincronizzata in quel momento.
- `UNSYNCED_NOTES_SENT` → Pulling

#### Pulling
Prima ogni cartella del cloud sovrascrive sempre quella locale. Poi, per ogni nota del cloud: se il dispositivo non la ha, oppure la sua copia locale non è stata modificata dopo quella del cloud, la versione del cloud sostituisce quella locale e il suo file nel vault viene riscritto; altrimenti resta la copia locale. Quando la versione del cloud sostituisce quella locale, le sue immagini e i suoi disegni che mancano sul dispositivo vengono scaricati; se un download non riesce, l'errore viene solo annotato nel registro dell'app, senza avvisare l'utente, la nota arriva senza quell'allegato e la sincronizzazione prosegue; il download viene ritentato alla sincronizzazione successiva in cui la versione del cloud sostituisce di nuovo quella locale. Se la cartella della nota del cloud non esiste sul dispositivo, la nota va nella cartella "Note", senza cambiare la data di modifica. Note e cartelle presenti solo sul dispositivo non vengono toccate.
- `COMPLETED` → Idle: registra l'ora dell'ultima sincronizzazione.

## Events

### CHANGE_SENT
Emesso per ogni cambiamento in coda che il cloud ha accettato.

### CHANGE_DISCARDED
Emesso per ogni cambiamento in coda tolto senza essere inviato: un salvataggio di nota non più recente della copia del cloud, un salvataggio di una nota eliminata nel cloud, oppure un'eliminazione di nota o di cartella più vecchia dell'ultima modifica sul cloud.

### CLOUD_DELETED_NOTE_REMOVED
Emesso per ogni nota già sincronizzata che viene eliminata definitivamente dal dispositivo perché ha un salvataggio in coda ma il cloud non la ha più.

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
Emesso quando cartelle e note del cloud sono state applicate.

### FAILED
Emesso al primo errore in qualsiasi passo, tranne il download non riuscito di un allegato di una nota del cloud.

### FINISHED
Emesso a ogni ritorno a riposo, dopo un completamento o un errore: l'app ricarica allora cartelle, tag ed elenco delle note.
