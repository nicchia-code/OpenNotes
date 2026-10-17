# Pending change

Un cambiamento locale di una nota o di una cartella in attesa di essere inviato al cloud: il salvataggio di una nota, che porta con sé la nota intera, l'eliminazione definitiva di una nota, oppure la creazione, la rinomina o l'eliminazione di una cartella. Nasce a ogni salvataggio o eliminazione definitiva di una nota fatti sul dispositivo (creazione, modifica, fissaggio, blocco, spostamento, cestino, ripristino, duplicazione, svuotamento del cestino, passaggio nella cartella "Note" perché l'utente ha eliminato la sua cartella) e a ogni creazione, rinomina o eliminazione di una cartella dell'utente, anche quando nessun utente è connesso. Non nasce quando una nota o una cartella arriva dal cloud, quando le note di una cartella eliminata altrove passano nella cartella "Note", né per i salvataggi di una nota di benvenuto mai sincronizzata, il cui destino viene deciso dalla sincronizzazione. Per ogni nota o cartella c'è al più un cambiamento in attesa: un nuovo salvataggio o una nuova modifica della cartella prende il posto di quello già in attesa, che conserva la sua posizione nell'ordine di invio e la revisione del cloud su cui si basa; un'eliminazione definitiva prende il posto di un salvataggio in attesa della stessa nota.

## States

### Pending (initial)
Il cambiamento attende sul dispositivo e ricorda il momento in cui è entrato in coda e la revisione del cloud su cui si basa.
- `sync-run.CHANGE_DISCARDED` → Discarded: solo per questo cambiamento; viene tolto dalla coda senza essere inviato, perché vince la versione del cloud.
- `sync-run.PREVIOUS_ACCOUNT_NOTE_REMOVED` → Discarded: solo se il cambiamento riguarda la nota rimossa per il cambio di account; viene tolto dalla coda senza essere inviato e la modifica va persa.
- `note.PERMANENTLY_DELETED` → Discarded: solo se il cambiamento è un salvataggio della nota eliminata definitivamente dall'utente (singolarmente o svuotando il cestino); la cancellazione nel cloud prende il suo posto nella coda.
- `realtime-channel.CLOUD_NOTE_REMOVED` → Discarded: solo se il cambiamento riguarda la nota eliminata nel cloud e rimossa dal dispositivo dal canale in tempo reale, perché l'eliminazione è più recente della modifica; viene tolto dalla coda subito, senza essere inviato e senza attendere la sincronizzazione.
- `note.SAVED` → Queued: solo se il cambiamento riguarda la stessa nota e il salvataggio è fatto sul dispositivo; prende la nuova versione della nota e torna in coda con il conteggio dei rifiuti azzerato.

#### Queued (initial)
Il cambiamento attende il suo turno nell'ordine in cui è nato. Se nessun utente è connesso, se la rete manca o se il giro si interrompe, resta in coda fino a un giro successivo, senza limite di tentativi.
- `sync-run.CHANGE_SENT` → Sent: solo per questo cambiamento; viene tolto dalla coda.
- `sync-run.CHANGE_REJECTED` → Queued: solo per questo cambiamento, al primo o al secondo rifiuto di fila; resta al suo posto e verrà ritentato al giro successivo.
- `sync-run.CHANGE_REJECTED` → Set aside: solo per questo cambiamento, al terzo rifiuto di fila.

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
