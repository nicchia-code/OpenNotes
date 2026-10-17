# Sync run

Una sincronizzazione bidirezionale tra note e cartelle del dispositivo e quelle dell'utente connesso sul cloud. Ne gira al massimo una alla volta. Ogni giro è incrementale, cioè scarica solo ciò che sul cloud è cambiato dopo l'ultima revisione già scaricata, oppure un controllo completo, che legge tutto. Le richieste che arrivano mentre un giro è in corso non vanno perse: vengono ricordate e alla fine del giro ne fanno partire uno solo nuovo, che è un controllo completo se almeno una di esse lo chiedeva. Ogni avvio richiede il collegamento al cloud pronto e un utente connesso; le richieste arrivate prima che il collegamento sia pronto vengono ignorate. La sincronizzazione non blocca mai l'uso dell'app.

## States

### Idle (initial)
Nessuna sincronizzazione in corso e nessun tentativo programmato.
- `supabase.INITIAL_SESSION` → Running: solo se l'evento porta una sessione; è la sincronizzazione dell'avvio, un controllo completo; l'app intanto è già mostrata e utilizzabile.
- `supabase.SIGNED_IN` → Running: solo se l'evento porta una sessione; controllo completo.
- `supabase.TOKEN_REFRESHED` → Running: solo se l'evento porta una sessione; giro incrementale.
- `user.SYNC_NOW` → Running: controllo completo.
- `user.PULL_TO_REFRESH` → Running: solo se un utente è connesso; controllo completo.
- `pending-change.QUEUED` → Running: solo se un utente è connesso; giro incrementale; chi ha accodato il cambiamento non attende la fine.
- `pending-change.CLOUD_VERSION_REQUESTED` → Running: giro incrementale che scarica e applica anche la versione del cloud scelta dall'utente.
- `operating-system.APP_RETURNED_TO_FOREGROUND` → Running: solo se un utente è connesso; giro incrementale.
- `time.SYNC_INTERVAL_ELAPSED` → Running: solo se un utente è connesso; giro incrementale.
- `realtime-channel.RECONNECTED` → Running: giro incrementale, che recupera le modifiche fatte altrove mentre il canale era interrotto.
- `realtime-channel.CHANGE_NOT_APPLIED` → Running: giro incrementale, che recupera la modifica che il canale non è riuscito ad applicare.
- `operating-system.NETWORK_LOST` → Offline

### Running
L'app segnala che una sincronizzazione è in corso. Ogni riga inviata al cloud viene assegnata all'utente connesso. Ogni richiesta al cloud e il giro intero hanno un tempo massimo: se uno dei due scade il giro fallisce, così una richiesta che non risponde non blocca le sincronizzazioni successive. Le modifiche ricevute in tempo reale continuano a essere applicate durante il giro. Tutti gli avvii dello stato di riposo, e il ritorno della rete, che arrivano durante il giro vengono ricordati per il giro successivo.
- `FAILED` → Waiting to retry: se il sistema segnala che la rete c'è. L'errore viene annotato nel registro dell'app e l'app ne mostra la categoria; l'ora dell'ultima sincronizzazione non cambia. Ciò che era già stato fatto resta fatto. Le richieste ricordate durante il giro confluiscono nel nuovo tentativo.
- `FAILED` → Offline: se il sistema segnala che la rete manca; il controllo completo eventualmente in corso o richiesto viene ricordato per il ritorno della rete.

#### Pushing changes (initial)
Prima confronta l'utente connesso con l'ultimo che ha sincronizzato il dispositivo: se è un altro utente, elimina definitivamente dal dispositivo le note già sincronizzate, cestinate e protette comprese, insieme al loro file nel vault e senza accodare nulla, e scarta i loro cambiamenti ancora in attesa; da allora ricorda il nuovo utente; le note mai sincronizzate restano. Se il dispositivo non ricorda nessun utente, ricorda quello connesso senza eliminare nulla. Poi invia al cloud i cambiamenti in coda, dal più vecchio al più recente, saltando quelli messi da parte. Ogni cambiamento porta la revisione del cloud su cui si basa, e il cloud lo accetta solo se nel frattempo quella nota o cartella non è cambiata; quando lo accetta, il dispositivo ricorda la nuova revisione e toglie il cambiamento dalla coda.
- salvataggio di una nota: prima carica le immagini e i disegni della nota che il cloud non ha ancora; un caricamento non riuscito viene annotato nel registro e ritentato al giro successivo, senza fermare l'invio della nota. Se la nota del cloud è cambiata nel frattempo vince l'ultima modifica: se la copia locale è stata modificata strettamente dopo quella del cloud viene inviata sopra di essa, altrimenti il salvataggio viene scartato e la versione del cloud arriva con il download. Se il cloud ha la nota come eliminata definitivamente: se l'eliminazione è successiva all'ultima modifica locale, il salvataggio viene scartato e la nota viene eliminata dal dispositivo insieme al suo file nel vault; altrimenti la nota rinasce sul cloud con la versione locale;
- eliminazione definitiva di una nota: il cloud conserva la nota come segnaposto di eliminazione, senza contenuto, con l'ora dell'eliminazione; se la nota del cloud è stata modificata dopo l'eliminazione, l'eliminazione viene scartata e la nota torna sul dispositivo con il download;
- creazione o rinomina di una cartella: come il salvataggio di una nota, con le stesse regole per i conflitti e per le cartelle eliminate altrove;
- eliminazione di una cartella: come l'eliminazione definitiva di una nota; quando il cloud la accetta, le sue sottocartelle diventano di primo livello.

Un cambiamento che il cloud rifiuta (dati non validi, permessi) viene contato come rifiutato e si passa al successivo; un errore di rete, un tempo scaduto o una sessione scaduta fanno fallire il giro.
- `QUEUE_SENT` → Reading cloud

#### Reading cloud
In un giro incrementale legge dal cloud solo le note e le cartelle dell'utente cambiate dopo l'ultima revisione scaricata, eliminazioni comprese, più quelle di cui l'utente ha scelto la versione del cloud; nel controllo completo le legge tutte. Finché il dispositivo non ha completato un controllo completo con le revisioni, per esempio al primo giro dopo l'aggiornamento dell'app, ogni giro è un controllo completo.
- `CLOUD_READ` → Sending unsynced notes

#### Sending unsynced notes
Esamina ogni nota del dispositivo, cestinate comprese, che non è mai stata sincronizzata. Se il cloud ha almeno una nota non eliminata e la nota ha esattamente il titolo di una delle due note di benvenuto, la elimina definitivamente dal dispositivo insieme al suo file nel vault; altrimenti la invia al cloud con le sue immagini e i suoi disegni, la segna come sincronizzata in quel momento e ne ricorda la revisione.
- `UNSYNCED_NOTES_SENT` → Pulling

#### Pulling
Applica prima le cartelle e poi le note lette dal cloud. Una nota o una cartella di cui il dispositivo conosce già quella revisione non viene toccata, salvo che l'utente ne abbia scelto la versione del cloud, che la sostituisce sempre. Per le altre:
- eliminata altrove: se il dispositivo non ha una modifica in attesa, in coda o messa da parte, successiva all'eliminazione, la elimina dal dispositivo, una nota insieme al suo file nel vault e una cartella spostando le sue note nella cartella "Note", e scarta le sue modifiche in attesa; altrimenti resta la copia locale, che rinascerà sul cloud;
- modificata altrove: se il dispositivo non ha una modifica in attesa successiva a quella del cloud, la versione del cloud sostituisce quella locale, il file nel vault di una nota viene riscritto, le modifiche in attesa più vecchie vengono scartate e il dispositivo ricorda la nuova revisione; altrimenti resta la copia locale;
- già sincronizzata ma senza revisione nota (primo giro dopo l'aggiornamento): se coincide con la versione del cloud ne adotta la revisione; altrimenti vince l'ultima modifica, e se vince la copia locale questa entra in coda per essere inviata.

Se la cartella di una nota del cloud non esiste sul dispositivo, la nota va nella cartella "Note", senza cambiare la data di modifica. Poi, per tutte le note del dispositivo, vengono scaricate le immagini e i disegni che mancano; un download non riuscito viene solo annotato nel registro dell'app, la nota resta senza quell'allegato e il download viene ritentato al giro successivo. Nel controllo completo, infine, le note e le cartelle già sincronizzate che il cloud non ha più, nemmeno come segnaposto di eliminazione, vengono eliminate dal dispositivo come quelle eliminate altrove; quelle mai sincronizzate restano.
- `COMPLETED` → Idle: se durante il giro non è arrivata nessuna richiesta. Registra l'ora dell'ultima sincronizzazione, che resta anche dopo un riavvio, e la revisione più alta scaricata.
- `COMPLETED` → Running: se durante il giro è arrivata almeno una richiesta. Registra come sopra e fa partire subito un solo nuovo giro, controllo completo se almeno una delle richieste lo chiedeva.

### Waiting to retry
L'ultimo giro è fallito e il prossimo tentativo è programmato dopo un'attesa che cresce a ogni fallimento di fila. La sincronizzazione periodica non scatta in questo stato. L'app mostra la categoria dell'errore e fra quanto avverrà il tentativo. Un avvio che arriva in questo stato riprova subito e, se il tentativo fallisce ancora, le attese ricominciano dalla prima.
- `time.SYNC_RETRY_DUE` → Running: nuovo tentativo, controllo completo se lo era il giro fallito o se una richiesta ricordata lo chiedeva.
- `pending-change.QUEUED` → Running: subito.
- `pending-change.CLOUD_VERSION_REQUESTED` → Running: subito, scaricando anche la versione del cloud scelta dall'utente.
- `user.SYNC_NOW` → Running: subito, controllo completo.
- `user.PULL_TO_REFRESH` → Running: subito, controllo completo.
- `operating-system.APP_RETURNED_TO_FOREGROUND` → Running: subito.
- `realtime-channel.RECONNECTED` → Running: subito.
- `supabase.SIGNED_IN` → Running: solo se l'evento porta una sessione; subito, controllo completo.
- `supabase.TOKEN_REFRESHED` → Running: solo se l'evento porta una sessione; subito.
- `operating-system.NETWORK_LOST` → Offline: il tentativo programmato viene annullato.
- `supabase.SIGNED_OUT` → Idle: il tentativo programmato viene annullato; i cambiamenti restano in coda.

### Offline
Il sistema segnala che il dispositivo non ha rete: nessun tentativo automatico e nessuna sincronizzazione periodica; i cambiamenti restano in coda. Le richieste fatte a mano provano comunque.
- `operating-system.NETWORK_AVAILABLE` → Running: se un utente è connesso; controllo completo se ne era stato ricordato uno, altrimenti giro incrementale.
- `operating-system.NETWORK_AVAILABLE` → Idle: se nessun utente è connesso.
- `supabase.INITIAL_SESSION` → Offline: solo se l'evento porta una sessione; ricorda che al ritorno della rete serve un controllo completo.
- `user.SYNC_NOW` → Running: controllo completo, anche senza rete.
- `user.PULL_TO_REFRESH` → Running: solo se un utente è connesso; controllo completo, anche senza rete.

## Events

### CHANGE_SENT
Emesso per ogni cambiamento in coda che il cloud ha accettato.

### CHANGE_DISCARDED
Emesso per ogni cambiamento in attesa tolto senza essere inviato perché la versione del cloud vince: un salvataggio di una nota o di una cartella modificata dopo sul cloud o eliminata sul cloud dopo l'ultima modifica locale, un'eliminazione più vecchia dell'ultima modifica sul cloud, oppure una modifica in attesa più vecchia di una versione del cloud applicata durante il download.

### CHANGE_REJECTED
Emesso per ogni cambiamento in coda che il cloud rifiuta perché non valido o non permesso; non per errori di rete, tempi scaduti o conflitti.

### QUEUE_SENT
Emesso quando tutti i cambiamenti in coda non messi da parte sono stati inviati, scartati o rifiutati.

### CLOUD_READ
Emesso quando le note e le cartelle del cloud da esaminare sono state lette.

### SAMPLE_NOTE_DISCARDED
Emesso per ogni nota di benvenuto mai sincronizzata che viene eliminata definitivamente dal dispositivo perché il cloud ha già delle note non eliminate.

### PREVIOUS_ACCOUNT_NOTE_REMOVED
Emesso per ogni nota già sincronizzata che viene eliminata definitivamente dal dispositivo perché l'utente connesso è diverso dall'ultimo che ha sincronizzato il dispositivo.

### UNSYNCED_NOTES_SENT
Emesso quando tutte le note mai sincronizzate sono state inviate o scartate.

### CLOUD_NOTE_APPLIED
Emesso per ogni nota del cloud che crea o sostituisce la copia locale.

### CLOUD_NOTE_REMOVED
Emesso per ogni nota eliminata definitivamente dal dispositivo perché è stata eliminata altrove dopo la sua ultima modifica locale, scoperto inviando un suo salvataggio o durante il download, oppure perché il controllo completo ha trovato che il cloud non la ha più.

### CLOUD_FOLDER_REMOVED
Emesso per ogni cartella eliminata dal dispositivo perché è stata eliminata altrove dopo la sua ultima modifica locale, oppure perché il controllo completo ha trovato che il cloud non la ha più.

### COMPLETED
Emesso quando cartelle e note del cloud sono state applicate.

### FAILED
Emesso al primo errore di rete, tempo scaduto, sessione scaduta o errore imprevisto in qualsiasi passo; non per un cambiamento rifiutato dal cloud né per un allegato non caricato o non scaricato.

### FINISHED
Emesso a ogni fine di giro, dopo un completamento o un errore: l'app ricarica allora cartelle, tag ed elenco delle note.
