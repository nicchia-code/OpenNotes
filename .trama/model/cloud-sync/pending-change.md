# Pending change

Un cambiamento locale di una nota o di una cartella in attesa di essere inviato al cloud: il salvataggio di una nota, che porta con sé la nota intera, l'eliminazione definitiva di una nota, oppure la creazione, la rinomina o l'eliminazione di una cartella. Nasce a ogni salvataggio o eliminazione definitiva di una nota fatti sul dispositivo (creazione, modifica, fissaggio, blocco, spostamento, cestino, ripristino, duplicazione, svuotamento del cestino, passaggio nella cartella "Note" perché l'utente ha eliminato la sua cartella) e a ogni creazione, rinomina o eliminazione di una cartella dell'utente, anche quando nessun utente è connesso. Nasce anche come salvataggio dal primo giro dopo l'aggiornamento dell'app, per una nota o una cartella già sincronizzata ma senza revisione nota che differisce dalla copia del cloud ed è strettamente più recente: si basa sulla revisione del cloud appena letta. Non nasce quando una nota o una cartella arriva dal cloud, quando le note di una cartella eliminata altrove passano nella cartella "Note", né per i salvataggi di una nota di benvenuto mai sincronizzata, il cui destino viene deciso dalla sincronizzazione. Per ogni nota o cartella c'è al più un cambiamento in attesa: un nuovo salvataggio o una nuova modifica della cartella prende il posto di quello già in attesa, che conserva la sua posizione nell'ordine di invio e la revisione del cloud su cui si basa; un'eliminazione definitiva prende il posto di un salvataggio in attesa della stessa nota.

## States

### Pending (initial)
Il cambiamento attende sul dispositivo, in coda o messo da parte, e ricorda il momento in cui è entrato in coda o è stato aggiornato e la revisione del cloud su cui si basa. Le transizioni di questo stato valgono sia per un cambiamento in coda sia per uno messo da parte.
- `sync-run.CHANGE_DISCARDED` → Discarded: solo per questo cambiamento, quando vince la versione del cloud; viene tolto dalla coda senza essere inviato.
- `sync-run.PREVIOUS_ACCOUNT_NOTE_REMOVED` → Discarded: solo se il cambiamento riguarda una nota già sincronizzata dal precedente account che è rimossa dal dispositivo per il cambio di account oppure era già stata eliminata definitivamente prima del cambio; viene tolto dalla coda senza essere inviato e la modifica va persa.
- `sync-run.CLOUD_NOTE_REMOVED` → Discarded: solo se il cambiamento riguarda la nota eliminata dal dispositivo dalla sincronizzazione, perché è stata eliminata altrove dopo la sua ultima modifica locale o perché il cloud non la ha più; viene tolto dalla coda senza essere inviato.
- `realtime-channel.CLOUD_NOTE_REMOVED` → Discarded: solo se il cambiamento riguarda la nota eliminata nel cloud e rimossa dal dispositivo dal canale in tempo reale, perché l'eliminazione è più recente della modifica; viene tolto dalla coda subito, senza essere inviato e senza attendere la sincronizzazione.
- `realtime-channel.CLOUD_NOTE_APPLIED` → Discarded: solo se il cambiamento riguarda la nota la cui versione del cloud, ricevuta in tempo reale, ha sostituito la copia locale perché il cambiamento non era strettamente più recente; viene tolto dalla coda senza essere inviato.
- `supabase.REMOTE_FOLDER_CHANGED` → Discarded: solo se il cambiamento riguarda la cartella la cui versione del cloud, ricevuta in tempo reale, sostituisce la copia locale perché il cambiamento non è strettamente più recente; vale anche per l'eliminazione in coda di una cartella, che fa tornare la cartella eliminata; viene tolto dalla coda senza essere inviato.
- `note.SAVED` → Queued: solo se il cambiamento riguarda la stessa nota, il salvataggio è fatto sul dispositivo e non è di una nota di benvenuto mai sincronizzata; prende la nuova versione della nota, torna in coda al suo posto con il conteggio dei rifiuti azzerato e non più messo da parte, ed emette QUEUED.
- `note.PERMANENTLY_DELETED` → Queued: solo se il cambiamento è un salvataggio della nota eliminata definitivamente dall'utente (singolarmente o svuotando il cestino); l'eliminazione definitiva prende il suo posto, torna in coda al suo posto con il conteggio dei rifiuti azzerato e non più messa da parte, ed emette QUEUED.
- `user.RENAME_FOLDER` → Queued: solo se il cambiamento riguarda la stessa cartella; prende il nuovo nome, torna in coda al suo posto con il conteggio dei rifiuti azzerato e non più messo da parte, ed emette QUEUED.
- `folder.DELETED` → Queued: solo se il cambiamento riguarda la cartella eliminata dall'utente; l'eliminazione della cartella prende il suo posto, torna in coda al suo posto con il conteggio dei rifiuti azzerato e non più messa da parte, ed emette QUEUED.

#### Queued (initial)
Il cambiamento attende il suo turno nell'ordine in cui è nato. È lo stato sia di un cambiamento appena entrato in coda sia di uno già rifiutato una o due volte, che si distinguono solo per il conteggio dei rifiuti. Se nessun utente è connesso, se la rete manca o se il giro si interrompe, resta in coda fino a un giro successivo, senza limite di tentativi.
- `sync-run.CHANGE_SENT` → Sent: solo per questo cambiamento; viene tolto dalla coda.
- `sync-run.CHANGE_REJECTED` → Queued: solo per questo cambiamento, al primo o al secondo rifiuto di fila; resta al suo posto e verrà ritentato al giro successivo.
- `sync-run.CHANGE_REJECTED` → Set aside: solo per questo cambiamento, al terzo rifiuto di fila.
- `sync-run.CHANGE_DISCARDED` → Discarded: solo se il cambiamento è un salvataggio di una nota mai sincronizzata che ora ha esattamente il titolo di una delle due note di benvenuto; al suo turno viene tolto dalla coda senza essere inviato e il destino della nota passa all'invio delle note mai sincronizzate, che la elimina se il cloud ha già delle note non eliminate oppure la invia con il testo attuale.

#### Set aside
Il cloud ha rifiutato il cambiamento tre volte di fila: non viene più inviato da solo e non blocca gli altri cambiamenti. La nota o la cartella compare tra quelle non sincronizzate e l'indicatore della sincronizzazione segnala il problema.
- `user.RETRY_SET_ASIDE_CHANGE` → Queued: torna in coda al suo posto con il conteggio dei rifiuti azzerato ed emette QUEUED.
- `user.USE_CLOUD_VERSION` → Discarded: solo se il cloud ha una copia non eliminata della nota o della cartella; la modifica locale viene abbandonata ed emette CLOUD_VERSION_REQUESTED, così la versione del cloud viene scaricata e sostituisce quella locale.

### Sent (final)
Il cloud ha accettato il cambiamento.

### Discarded (final)
Il cambiamento è stato tolto dalla coda senza raggiungere il cloud. L'utente non viene avvisato, salvo quando è lui a scegliere la versione del cloud.

## Events

### QUEUED
Emesso quando il cambiamento entra in coda, quando un nuovo salvataggio o una nuova modifica prende il posto di quello in attesa, e quando l'utente lo rimette in coda.

### CLOUD_VERSION_REQUESTED
Emesso quando l'utente sceglie la versione del cloud di una nota o di una cartella messa da parte.
