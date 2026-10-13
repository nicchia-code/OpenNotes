# Note editor

L'editor della nota aperta: la colonna di destra su desktop, una schermata a tutto schermo su mobile. Carica il contenuto della nota in un documento fatto di parti (sezioni di testo, tabelle, immagini, separatori) e consegna il documento intero per il salvataggio a ogni modifica.

## States

### Closed (initial)
Nessuna nota è aperta nell'editor.
- `note-selection.SELECTED_NOTE_CHANGED` → Open: se è stata selezionata una nota non protetta, oppure protetta ma già sbloccata in questa sessione. Carica il documento e rende attiva la seconda parte, o la prima se ce n'è una sola.
- `note-selection.SELECTED_NOTE_CHANGED` → Protected: se è stata selezionata una nota protetta e non ancora sbloccata in questa sessione. Il documento viene caricato ma non mostrato.

### Protected
Al posto del contenuto c'è il segnaposto «Questa nota è protetta» con il pulsante «Visualizza nota», che chiede il PIN principale. Il documento resta caricato e i comandi della barra degli strumenti (desktop) e della barra sopra la tastiera (mobile) continuano a modificarlo e a salvarlo, anche se non si vede.
- `note-access.UNLOCKED` → Open: se riguarda la nota aperta.
- `note-access.PROTECTION_REMOVED` → Open: se riguarda la nota aperta.
- `note-selection.SELECTED_NOTE_CHANGED` → Open: se la nuova nota non è protetta oppure è già sbloccata; carica il suo documento.
- `note-selection.SELECTED_NOTE_CHANGED` → Protected: se anche la nuova nota è protetta e non sbloccata; carica il suo documento.
- `note-selection.SELECTED_NOTE_CHANGED` → Closed: se non è più selezionata nessuna nota.
- `user.NAVIGATE_BACK` → Closed: su mobile, se l'editor è la schermata in primo piano.
- `user.TOGGLE_CHECKLIST` → Protected: modifica il documento nascosto (alterna la voce di checklist nella parte attiva, oppure aggiunge in fondo una voce vuota se il testo della nota non è mai stato mostrato da quando l'app è aperta; cambi di stile e ricariche remote non contano come testo mostrato) e lo salva subito.
- `user.SET_TEXT_STYLE` → Protected: cambia lo stile della parte attiva del documento nascosto e lo salva subito.
- `user.TOGGLE_BOLD` → Protected: salva subito il documento nascosto, aggiornando la data di modifica; il grassetto si applica solo se il testo era già stato mostrato.
- `user.TOGGLE_ITALIC` → Protected: come per il grassetto.
- `user.TOGGLE_UNDERLINE` → Protected: come per il grassetto.
- `user.INSERT_TABLE` → Protected: inserisce una tabella nel documento nascosto e lo salva subito.
- `user.INSERT_PHOTO` → Protected: inserisce la foto nel documento nascosto e lo salva subito.
- `drawing-canvas.DRAWING_SAVED` → Protected: inserisce il disegno nel documento nascosto e lo salva subito.
- `sync-run.CLOUD_NOTE_APPLIED` → Protected: se riguarda la nota aperta, il nuovo contenuto è diverso dall'ultimo salvato dall'editor e nessuna riga di testo ha il focus. Ricarica il documento nascosto, che resta non mostrato. Altrimenti la versione remota viene ignorata.
- `realtime-channel.CLOUD_NOTE_APPLIED` → Protected: alle stesse condizioni della sincronizzazione completa; ricarica il documento nascosto, che resta non mostrato.

### Open
Mostra la data dell'ultima modifica, i tag della nota e il documento modificabile. Le sezioni di testo sono fatte di righe (vedi la macchina delle righe) con la formattazione dei caratteri; tabelle e immagini sono parti a sé. La parte attiva è quella che ha il focus, altrimenti l'ultima che lo ha avuto. La nota resta modificabile anche quando è nel cestino.
- `note-access.RELOCKED` → Protected: se riguarda la nota aperta.
- `note-selection.SELECTED_NOTE_CHANGED` → Open: se la nuova nota non è protetta oppure è già sbloccata. Scarta senza salvarla l'eventuale modifica in attesa, chiude i menu e carica il nuovo documento.
- `note-selection.SELECTED_NOTE_CHANGED` → Protected: se la nuova nota è protetta e non sbloccata. Scarta l'eventuale modifica in attesa.
- `note-selection.SELECTED_NOTE_CHANGED` → Closed: se non è più selezionata nessuna nota. Scarta l'eventuale modifica in attesa.
- `user.NAVIGATE_BACK` → Closed: su mobile, se l'editor è la schermata in primo piano. Scarta l'eventuale modifica in attesa. L'editor mobile si chiude allo stesso modo quando la nota aperta viene spostata nel cestino o eliminata dal suo menu.
- `sync-run.CLOUD_NOTE_APPLIED` → Idle: se riguarda la nota aperta, il nuovo contenuto è diverso dall'ultimo salvato dall'editor e nessuna riga di testo ha il focus. Scarta la modifica in attesa, chiude i menu e ricarica il documento. Altrimenti la versione remota viene ignorata.
- `realtime-channel.CLOUD_NOTE_APPLIED` → Idle: se riguarda la nota aperta, il nuovo contenuto è diverso dall'ultimo salvato dall'editor e nessuna riga di testo ha il focus. Scarta la modifica in attesa, chiude i menu e ricarica il documento. Altrimenti la versione remota viene ignorata.
- `user.EDIT_NOTE_TEXT` → Save pending: aggiorna il testo, sposta formattazione e stili di riga e applica le scorciatoie Markdown.
- `user.PRESS_ENTER_IN_TEXT` → Save pending: su una voce di elenco, di checklist o numerata, o su una riga di titolo o intestazione applica le regole di continuazione. Altrove va semplicemente a capo.
- `user.PRESS_TAB_IN_TEXT` → Save pending: aumenta il rientro delle righe selezionate, o lo riduce se si tiene premuto Maiuscole.
- `user.PRESS_BACKSPACE_IN_TEXT` → Idle: se il cursore è all'inizio di una sezione di testo preceduta da un'altra sezione di testo. Unisce le due sezioni, mette il cursore nel punto di giunzione e salva subito.
- `user.PRESS_BACKSPACE_IN_TEXT` → Save pending: se il cursore non è all'inizio di una sezione. Subito dopo il simbolo di una voce puntata o di checklist riduce il rientro o toglie il simbolo, altrimenti cancella normalmente. All'inizio di una sezione preceduta da una tabella o da un'immagine, oppure all'inizio del documento, non succede nulla.
- `user.TOGGLE_BOLD` → Idle: alterna il grassetto sulla selezione della parte attiva, oppure per il testo che verrà digitato se non c'è selezione. Rimette il focus e salva subito.
- `user.TOGGLE_ITALIC` → Idle: come per il grassetto, con il corsivo.
- `user.TOGGLE_UNDERLINE` → Idle: come per il grassetto, con il sottolineato.
- `user.TOGGLE_STRIKETHROUGH` → Idle: come per il grassetto, con il barrato (solo da tastiera).
- `user.SET_TEXT_STYLE` → Idle: applica lo stile scelto alle righe selezionate della parte attiva e salva subito.
- `user.TOGGLE_CHECKLIST` → Idle: alterna la voce di checklist sulla riga del cursore, oppure la crea, e salva subito.
- `user.TAP_CHECKBOX` → Idle: se il tocco cade sul cerchio di una voce di checklist e cambia la spunta. Salva subito.
- `user.PICK_TAG_SUGGESTION` → Idle: completa il tag che si sta scrivendo e salva subito.
- `user.CONFIRM_TAG_SUGGESTION` → Idle: se c'è almeno un tag che corrisponde o è stato digitato del testo. Completa il tag e salva subito.
- `user.PICK_BLOCK_MENU_ITEM` → Idle: se la riga corrente comincia con una barra, toglie la barra e la parola che la segue; poi applica lo stile scelto. Per «Tabella» il testo della sezione resta (tolta solo la barra con la parola) e la tabella viene inserita dopo la sezione, come con il comando di inserimento tabella. Salva subito.
- `user.INSERT_TABLE` → Idle: inserisce una tabella di due righe e due colonne dopo la parte attiva (non nel punto del cursore). Se dopo non c'è già una sezione di testo, ne aggiunge una vuota. Salva subito.
- `user.EDIT_NOTE_TABLE` → Idle: aggiorna la tabella (testo di una cella, riga o colonna aggiunta o tolta) e salva subito, anche a ogni carattere.
- `user.INSERT_PHOTO` → Idle: copia l'immagine scelta tra gli allegati del vault e la inserisce dopo la parte attiva. Subito dopo aggiunge una nuova sezione di testo vuota, che riceve il focus. Salva subito.
- `drawing-canvas.DRAWING_SAVED` → Idle: inserisce il disegno come immagine, come per una foto.
- `user.REMOVE_IMAGE` → Idle: toglie l'immagine dal documento e salva subito. Il file allegato resta nel vault.
- `user.TAP_EMPTY_EDITOR_AREA` → Idle: se l'ultima parte del documento non è una sezione di testo vuota. Aggiunge in fondo una sezione di testo vuota, le dà il focus e salva subito. Altrimenti dà solo il focus all'ultima sezione.

#### Idle (initial)
Non ci sono modifiche in attesa di essere consegnate.

#### Save pending
Ci sono modifiche di testo non ancora consegnate. Ogni nuova modifica di testo fa ripartire l'attesa.
- `time.EDITOR_SAVE_DEBOUNCE_ELAPSED` → Idle: consegna per il salvataggio l'intero documento.
- `operating-system.APP_LEAVING_FOREGROUND` → Idle: consegna subito per il salvataggio l'intero documento, senza aspettare la fine dell'attesa.

## Events

### CONTENT_CHANGED
Emesso quando l'editor trasforma l'intero documento della nota aperta in contenuto salvabile e lo consegna per il salvataggio. Succede subito dopo i comandi di formattazione, stile, checklist, tabelle, immagini, unione di sezioni, tag e menu rapido, dopo una pausa nelle modifiche di testo, oppure subito quando l'app lascia il primo piano con modifiche di testo non ancora consegnate. Succede anche quando la nota è protetta e i comandi agiscono sul documento nascosto.
