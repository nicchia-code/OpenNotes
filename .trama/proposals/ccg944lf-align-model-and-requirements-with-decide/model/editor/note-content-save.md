# Note content save

Il salvataggio del contenuto consegnato dall'editor. Aggiorna subito la nota in memoria; dopo una breve attesa la scrive nel database locale e nel suo file Markdown e la segnala alla sincronizzazione. L'attesa è una sola, condivisa da tutte le note. La scrittura riporta solo ciò che viene dal contenuto (contenuto, titolo, tag, anteprima e data di modifica) sulla versione della nota già salvata, così fissaggio, protezione, cartella o cestino cambiati durante l'attesa non vengono sovrascritti.

## States

### Idle (initial)
Non c'è nessuna scrittura in attesa.
- `note-editor.CONTENT_CHANGED` → Waiting: se la nota è tra quelle dell'elenco caricato. Aggiorna subito in memoria contenuto, titolo, tag, data di modifica e anteprima, poi fa partire l'attesa.
- `note-editor.CONTENT_CHANGED` → Idle: se la nota è tra quelle dell'elenco caricato e l'editor consegna perché l'app sta lasciando il primo piano. Aggiorna la nota in memoria e la scrive subito, senza attesa, come allo scadere dell'attesa.

### Waiting
Una versione della nota aspetta di essere scritta.
- `note-editor.CONTENT_CHANGED` → Waiting: se la nota è tra quelle dell'elenco caricato. La aggiorna in memoria e fa ripartire l'attesa. La versione in attesa viene sostituita anche quando apparteneva a un'altra nota: quella nota non viene più scritta.
- `note-editor.CONTENT_CHANGED` → Idle: se la nota è tra quelle dell'elenco caricato e l'editor consegna perché l'app sta lasciando il primo piano. Aggiorna la nota in memoria e la scrive subito, senza attesa.
- `time.CONTENT_SAVE_DEBOUNCE_ELAPSED` → Idle: scrive la nota nel database locale, riscrive il suo file Markdown nel vault, la segnala alla sincronizzazione e ricalcola l'elenco dei tag.
- `operating-system.APP_LEAVING_FOREGROUND` → Idle: scrive subito la versione in attesa, come allo scadere dell'attesa. Su mobile il sistema può sospendere l'app prima che la scrittura finisca.

## Events

### NOTE_CONTENT_SAVED
Emesso quando la versione in attesa è stata scritta nel database locale e nel vault. La sincronizzazione mette la modifica in coda e la invia se il cloud è collegato.
