# Note content save

Il salvataggio del contenuto consegnato dall'editor. Aggiorna subito la nota in memoria; dopo una breve attesa la scrive nel database locale e nel suo file Markdown e la segnala alla sincronizzazione. L'attesa è una sola, condivisa da tutte le note. La scrittura riporta solo ciò che viene dal contenuto (contenuto, titolo, tag, anteprima e data di modifica) sulla versione della nota già salvata, così fissaggio, protezione, cartella o cestino cambiati durante l'attesa non vengono sovrascritti.

Se una scrittura fallisce, l'utente viene avvisato che la nota non è stata salvata e che il salvataggio verrà ritentato, e la versione non scritta torna in attesa: viene ritentata alla consegna successiva o al passaggio in secondo piano, e l'avviso sparisce alla prima scrittura riuscita. Se però al momento del fallimento è già in attesa un'altra versione, quella non scritta viene scartata: se apparteneva a un'altra nota, quella modifica va persa e la nota torna all'ultima versione salvata.

## States

### Idle (initial)
Non c'è nessuna scrittura in attesa.
- `note-editor.CONTENT_CHANGED` → Waiting: se la nota è tra quelle dell'elenco caricato. Aggiorna subito in memoria contenuto, titolo, tag, data di modifica e anteprima, poi fa partire l'attesa.
- `note-editor.CONTENT_CHANGED` → Idle: se la nota è tra quelle dell'elenco caricato e l'editor consegna perché l'app sta lasciando il primo piano, oppure perché sta per partire un comando sulla nota (fissare o togliere dalle fissate, proteggere o togliere la protezione, spostare nel cestino, ripristinare anche con «Annulla», spostare in un'altra cartella, duplicare). Aggiorna la nota in memoria e la scrive subito, senza attesa, come allo scadere dell'attesa.

### Waiting
Una versione della nota aspetta di essere scritta.
- `note-editor.CONTENT_CHANGED` → Waiting: se la nota è tra quelle dell'elenco caricato. La aggiorna in memoria e fa ripartire l'attesa. Se la versione in attesa apparteneva a un'altra nota, quella viene prima scritta subito, come allo scadere dell'attesa, e la nuova prende il suo posto in attesa.
- `note-editor.CONTENT_CHANGED` → Idle: se la nota è tra quelle dell'elenco caricato e l'editor consegna perché l'app sta lasciando il primo piano, oppure perché sta per partire un comando sulla nota. Aggiorna la nota in memoria e la scrive subito, senza attesa.
- `time.CONTENT_SAVE_DEBOUNCE_ELAPSED` → Idle: scrive la nota nel database locale, riscrive il suo file Markdown nel vault, la segnala alla sincronizzazione e ricalcola l'elenco dei tag.
- `operating-system.APP_LEAVING_FOREGROUND` → Idle: scrive subito la versione in attesa, come allo scadere dell'attesa. Su mobile il sistema può sospendere l'app prima che la scrittura finisca.
- `sync-run.CLOUD_NOTE_APPLIED` → Idle: se la versione del cloud applicata è protetta, anche se riguarda un'altra nota o una nota già protetta. Dopo che l'editor ha consegnato il testo ancora in attesa e prima che la nota venga nascosta, scrive subito la versione in attesa, come allo scadere dell'attesa, anche se appartiene a un'altra nota.
- `realtime-channel.CLOUD_NOTE_APPLIED` → Idle: alle stesse condizioni e con lo stesso effetto della sincronizzazione.
- `user.PIN_NOTE` → Idle: prima che il comando agisca, scrive subito la versione in attesa, come allo scadere dell'attesa, anche se appartiene a un'altra nota; il comando agisce poi sulla versione appena salvata.
- `user.UNPIN_NOTE` → Idle: come per il fissaggio.
- `user.LOCK_NOTE` → Idle: come per il fissaggio.
- `user.REMOVE_NOTE_LOCK` → Idle: come per il fissaggio.
- `user.MOVE_NOTE_TO_TRASH` → Idle: come per il fissaggio.
- `user.RESTORE_NOTE` → Idle: come per il fissaggio.
- `user.UNDO_MOVE_NOTE_TO_TRASH` → Idle: come per il fissaggio.
- `user.MOVE_NOTE_TO_FOLDER` → Idle: come per il fissaggio.
- `user.DUPLICATE_NOTE` → Idle: prima che la copia venga creata, scrive subito la versione in attesa, come allo scadere dell'attesa; la copia nasce poi dal testo appena salvato.

## Events

### NOTE_CONTENT_SAVED
Emesso quando la versione in attesa è stata scritta nel database locale e nel vault. La sincronizzazione mette la modifica in coda e la invia se il cloud è collegato.
