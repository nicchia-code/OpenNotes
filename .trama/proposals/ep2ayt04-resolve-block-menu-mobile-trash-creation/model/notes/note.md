# Note

Una nota dell'utente: titolo, contenuto (documento a blocchi o testo Markdown), cartella, tag, fissaggio, protezione con PIN ed eventuale permanenza nel cestino. Il titolo, i tag e l'anteprima sono ricavati dal contenuto.

## States

### Not yet created (initial)
La nota non esiste ancora sul dispositivo.
- `user.CREATE_NOTE` → Unpinned: nasce intitolata "Nuova nota" nella cartella selezionata, oppure nella cartella Note se la selezione è Tutte le note, Note rapide o nessuna; se è attivo un filtro per tag, i tag selezionati vengono scritti in testa al contenuto e assegnati alla nota; la salva e diventa la nota selezionata. Nel Cestino non si crea una nota.
- `user.DUPLICATE_NOTE` → Unpinned: nasce come copia di un'altra nota che non è nel cestino; se l'originale è protetta, solo dopo che l'utente ha inserito il PIN corretto; la copia ha il titolo dell'originale seguito da " (copia)", riscritto anche come titolo del contenuto, la stessa cartella, gli stessi tag e la stessa protezione, non è fissata e ha date di creazione e modifica nuove; la salva e diventa la nota selezionata.
- `operating-system.APP_LAUNCHED` → Pinned: nota di benvenuto "Benvenuto in OpenNotes", creata solo se all'avvio, dopo l'eventuale sincronizzazione iniziale, non esiste nessuna nota fuori dal cestino; nasce come una nota nuova non fissata e subito dopo viene fissata, con due salvataggi.
- `operating-system.APP_LAUNCHED` → Unpinned: nota di esempio "Pianificazione & Attività" con una tabella, creata nella stessa situazione subito dopo la nota di benvenuto.
- `sync-run.CLOUD_NOTE_APPLIED` → Pinned: la nota esiste solo nel cloud, è fissata e non è nel cestino; viene scritta sul dispositivo.
- `sync-run.CLOUD_NOTE_APPLIED` → Unpinned: la nota esiste solo nel cloud, non è fissata e non è nel cestino; viene scritta sul dispositivo.
- `sync-run.CLOUD_NOTE_APPLIED` → In trash: la nota esiste solo nel cloud ed è nel cestino; viene scritta sul dispositivo.
- `realtime-channel.CLOUD_NOTE_APPLIED` → Pinned: come per la sincronizzazione completa, per una nota fissata fuori dal cestino.
- `realtime-channel.CLOUD_NOTE_APPLIED` → Unpinned: come per la sincronizzazione completa, per una nota non fissata fuori dal cestino.
- `realtime-channel.CLOUD_NOTE_APPLIED` → In trash: come per la sincronizzazione completa, per una nota nel cestino.

### Active
La nota è fuori dal cestino: compare in Tutte le note, nella sua cartella, nei suoi tag e nella ricerca, ed è contata nella sua cartella.
- `user.MOVE_NOTE_TO_TRASH` → In trash: anche se protetta, senza chiedere il PIN; registra la data di eliminazione, aggiorna la data di modifica e conserva cartella, fissaggio e protezione; salva la nota; la selezione passa alla nota successiva dell'elenco, o alla precedente se era l'ultima; l'utente può annullare.
- `sync-run.CLOUD_NOTE_APPLIED` → In trash: solo se la versione locale non è più recente di quella del cloud e quella del cloud è nel cestino; la versione del cloud sostituisce quella locale.
- `sync-run.CLOUD_NOTE_APPLIED` → Pinned: solo se la versione locale non è più recente di quella del cloud e quella del cloud è fissata e fuori dal cestino; la versione del cloud sostituisce quella locale.
- `sync-run.CLOUD_NOTE_APPLIED` → Unpinned: solo se la versione locale non è più recente di quella del cloud e quella del cloud non è fissata ed è fuori dal cestino; la versione del cloud sostituisce quella locale.
- `realtime-channel.CLOUD_NOTE_APPLIED` → In trash: alle stesse condizioni della sincronizzazione completa, per una versione del cloud nel cestino.
- `realtime-channel.CLOUD_NOTE_APPLIED` → Pinned: alle stesse condizioni della sincronizzazione completa, per una versione del cloud fissata e fuori dal cestino.
- `realtime-channel.CLOUD_NOTE_APPLIED` → Unpinned: alle stesse condizioni della sincronizzazione completa, per una versione del cloud non fissata e fuori dal cestino.
- `realtime-channel.CLOUD_NOTE_REMOVED` → Deleted: la nota è stata eliminata nel cloud; viene rimossa dal dispositivo insieme al suo file nell'archivio Markdown, senza accodare nulla.
- `sync-run.SAMPLE_NOTE_DISCARDED` → Deleted: solo se la nota non è mai stata sincronizzata, ha esattamente il titolo di una delle due note di benvenuto e il cloud contiene già delle note; viene rimossa dal dispositivo insieme al suo file, senza accodare nulla.
- `sync-run.PREVIOUS_ACCOUNT_NOTE_REMOVED` → Deleted: solo se la nota è già stata sincronizzata e l'utente connesso è diverso dall'ultimo che ha sincronizzato il dispositivo; anche se protetta, senza chiedere il PIN; viene rimossa dal dispositivo insieme al suo file nell'archivio Markdown, senza accodare nulla; resta nel cloud dell'account precedente, mentre le sue modifiche non ancora inviate vanno perse.

#### Unpinned (initial)
La nota compare dopo le note fissate.
- `user.PIN_NOTE` → Pinned: aggiorna la data di modifica e salva la nota.
- `user.LOCK_NOTE` → Unpinned: solo se la nota non è protetta e un PIN principale esiste già o l'utente lo imposta in quel momento; l'anteprima diventa "Questa nota è protetta"; aggiorna la data di modifica e salva la nota.
- `user.REMOVE_NOTE_LOCK` → Unpinned: solo se la nota è protetta e l'utente inserisce il PIN corretto; l'anteprima torna a mostrare il testo; aggiorna la data di modifica e salva la nota.
- `user.MOVE_NOTE_TO_FOLDER` → Unpinned: verso una cartella diversa da quella attuale; aggiorna la data di modifica e salva la nota.
- `note-content-save.NOTE_CONTENT_SAVED` → Unpinned: con il nuovo contenuto ricava di nuovo titolo, tag e anteprima, aggiorna la data di modifica e salva la nota.
- `folder.DELETED` → Unpinned: solo se la nota era nella cartella eliminata; passa nella cartella Note senza aggiornare la data di modifica, senza riscrivere il file nell'archivio Markdown e senza accodare il cambiamento.
- `supabase.REMOTE_FOLDER_DELETED` → Unpinned: come per l'eliminazione locale della cartella.

#### Pinned
La nota compare in cima all'elenco, prima delle note non fissate.
- `user.UNPIN_NOTE` → Unpinned: aggiorna la data di modifica e salva la nota.
- `user.LOCK_NOTE` → Pinned: solo se la nota non è protetta e un PIN principale esiste già o l'utente lo imposta in quel momento; l'anteprima diventa "Questa nota è protetta"; aggiorna la data di modifica e salva la nota.
- `user.REMOVE_NOTE_LOCK` → Pinned: solo se la nota è protetta e l'utente inserisce il PIN corretto; l'anteprima torna a mostrare il testo; aggiorna la data di modifica e salva la nota.
- `user.MOVE_NOTE_TO_FOLDER` → Pinned: verso una cartella diversa da quella attuale; aggiorna la data di modifica e salva la nota.
- `note-content-save.NOTE_CONTENT_SAVED` → Pinned: con il nuovo contenuto ricava di nuovo titolo, tag e anteprima, aggiorna la data di modifica e salva la nota.
- `folder.DELETED` → Pinned: solo se la nota era nella cartella eliminata; passa nella cartella Note senza aggiornare la data di modifica, senza riscrivere il file nell'archivio Markdown e senza accodare il cambiamento.
- `supabase.REMOTE_FOLDER_DELETED` → Pinned: come per l'eliminazione locale della cartella.

### In trash
La nota è nel cestino: compare solo nella vista Cestino, conserva la cartella di origine, il fissaggio e la protezione, ed è esclusa dai conteggi delle cartelle e dall'elenco dei tag. Non viene mai eliminata automaticamente.
- `user.RESTORE_NOTE` → Pinned: se era fissata; torna nella cartella di origine, perde la data di eliminazione, aggiorna la data di modifica e salva la nota.
- `user.RESTORE_NOTE` → Unpinned: se non era fissata; torna nella cartella di origine, perde la data di eliminazione, aggiorna la data di modifica e salva la nota.
- `user.UNDO_MOVE_NOTE_TO_TRASH` → Pinned: se era fissata; stesso effetto del ripristino.
- `user.UNDO_MOVE_NOTE_TO_TRASH` → Unpinned: se non era fissata; stesso effetto del ripristino.
- `user.MOVE_NOTE_TO_FOLDER` → Pinned: se era fissata; viene ripristinata direttamente nella cartella scelta, diversa da quella di origine; perde la data di eliminazione, aggiorna la data di modifica e salva la nota.
- `user.MOVE_NOTE_TO_FOLDER` → Unpinned: se non era fissata; viene ripristinata direttamente nella cartella scelta, diversa da quella di origine; perde la data di eliminazione, aggiorna la data di modifica e salva la nota.
- `user.MOVE_NOTE_TO_TRASH` → In trash: con il comando di eliminazione della barra desktop sulla nota selezionata nella vista Cestino; registra di nuovo la data di eliminazione, aggiorna la data di modifica e salva la nota.
- `user.PIN_NOTE` → In trash: con il gesto di scorrimento nella vista Cestino; la nota resta nel cestino ma risulta fissata; aggiorna la data di modifica e salva la nota.
- `user.UNPIN_NOTE` → In trash: con il gesto di scorrimento nella vista Cestino; la nota resta nel cestino e non è più fissata; aggiorna la data di modifica e salva la nota.
- `user.LOCK_NOTE` → In trash: dal pulsante di protezione della barra desktop o dell'editor, alle stesse condizioni di una nota fuori dal cestino; la nota resta nel cestino.
- `user.REMOVE_NOTE_LOCK` → In trash: dal pulsante di protezione della barra desktop o dell'editor, alle stesse condizioni di una nota fuori dal cestino; la nota resta nel cestino.
- `note-content-save.NOTE_CONTENT_SAVED` → In trash: con il nuovo contenuto ricava di nuovo titolo, tag e anteprima, aggiorna la data di modifica e salva la nota, che resta nel cestino.
- `folder.DELETED` → In trash: solo se la cartella di origine della nota è quella eliminata; la cartella di origine diventa Note, senza aggiornare la data di modifica, senza riscrivere il file e senza accodare il cambiamento.
- `supabase.REMOTE_FOLDER_DELETED` → In trash: come per l'eliminazione locale della cartella.
- `user.DELETE_NOTE_PERMANENTLY` → Deleted: solo dopo che l'utente ha confermato che l'azione non può essere annullata e, se la nota è protetta, dopo aver inserito il PIN corretto; rimuove il file dall'archivio Markdown, accoda la cancellazione nel cloud e poi elimina la nota dal dispositivo.
- `user.EMPTY_TRASH` → Deleted: per tutte le note nel cestino, solo dopo la conferma dell'utente e, se una delle note mostrate nella vista Cestino è protetta, dopo aver inserito il PIN corretto; per ogni nota rimuove il file e accoda la cancellazione nel cloud, poi le elimina tutte dal dispositivo.
- `sync-run.CLOUD_NOTE_APPLIED` → Pinned: solo se la versione locale non è più recente di quella del cloud e quella del cloud è fissata e fuori dal cestino; la versione del cloud sostituisce quella locale.
- `sync-run.CLOUD_NOTE_APPLIED` → Unpinned: solo se la versione locale non è più recente di quella del cloud e quella del cloud non è fissata ed è fuori dal cestino; la versione del cloud sostituisce quella locale.
- `sync-run.CLOUD_NOTE_APPLIED` → In trash: solo se la versione locale non è più recente di quella del cloud e quella del cloud è nel cestino; la versione del cloud sostituisce quella locale.
- `realtime-channel.CLOUD_NOTE_APPLIED` → Pinned: alle stesse condizioni della sincronizzazione completa, per una versione del cloud fissata e fuori dal cestino.
- `realtime-channel.CLOUD_NOTE_APPLIED` → Unpinned: alle stesse condizioni della sincronizzazione completa, per una versione del cloud non fissata e fuori dal cestino.
- `realtime-channel.CLOUD_NOTE_APPLIED` → In trash: alle stesse condizioni della sincronizzazione completa, per una versione del cloud nel cestino.
- `realtime-channel.CLOUD_NOTE_REMOVED` → Deleted: la nota è stata eliminata nel cloud; viene rimossa dal dispositivo insieme al suo file, senza accodare nulla.
- `sync-run.SAMPLE_NOTE_DISCARDED` → Deleted: solo se la nota non è mai stata sincronizzata, ha esattamente il titolo di una delle due note di benvenuto e il cloud contiene già delle note; viene rimossa dal dispositivo insieme al suo file, senza accodare nulla.
- `sync-run.PREVIOUS_ACCOUNT_NOTE_REMOVED` → Deleted: alle stesse condizioni di una nota fuori dal cestino; viene rimossa dal dispositivo insieme al suo file, senza accodare nulla.

### Deleted (final)
La nota non esiste più sul dispositivo né nel suo archivio Markdown.

## Events

### CREATED
Emesso quando una nuova nota nasce sul dispositivo per creazione, duplicazione o come nota di benvenuto al primo avvio; la nuova nota diventa la nota selezionata.

### SAVED
Emesso ogni volta che la nota viene scritta sul dispositivo: nel database locale e come file nell'archivio Markdown. Per le modifiche fatte sul dispositivo accoda anche il cambiamento da inviare al cloud e, se l'utente è connesso, avvia una sincronizzazione; per le versioni ricevute dal cloud non accoda nulla.

### MOVED_TO_TRASH
Emesso quando la nota viene messa nel cestino, anche quando ci si trova già.

### RESTORED
Emesso quando la nota esce dal cestino per ripristino, annullamento dello spostamento nel cestino o spostamento in una cartella.

### PERMANENTLY_DELETED
Emesso quando la nota viene rimossa definitivamente dal dispositivo e il suo file viene cancellato dall'archivio Markdown: per eliminazione definitiva o svuotamento del cestino, che accodano anche la cancellazione nel cloud, oppure per cancellazione avvenuta nel cloud, scarto di una nota di benvenuto mai sincronizzata o cambio di account, che non accodano nulla.
