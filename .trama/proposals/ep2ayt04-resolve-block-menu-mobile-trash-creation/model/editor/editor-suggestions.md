# Editor suggestions

I menu che compaiono mentre si scrive nell'editor: i suggerimenti di tag e il menu rapido dei blocchi, aperto digitando una barra a inizio sezione oppure dal suo pulsante sulla barra sopra la tastiera del telefono.

## States

### Hidden (initial)
Nessun menu è aperto.
- `user.EDIT_NOTE_TEXT` → Tag suggestions: se il testo prima del cursore finisce con un cancelletto, all'inizio o dopo uno spazio, seguito solo da lettere latine, cifre, trattini o trattini bassi (anche da nessun carattere).
- `user.EDIT_NOTE_TEXT` → Block menu: se non si sta scrivendo un tag e la sezione di testo comincia con una barra.
- `user.OPEN_BLOCK_MENU` → Block menu: sotto la sezione di testo che ha il focus, anche se non comincia con una barra.

### Shown
- `user.EDIT_NOTE_TEXT` → Hidden: se non si sta più scrivendo un tag e la sezione di testo non comincia con una barra.
- `note-selection.SELECTED_NOTE_CHANGED` → Hidden
- `sync-run.CLOUD_NOTE_APPLIED` → Hidden: se l'editor ricarica il documento.
- `realtime-channel.CLOUD_NOTE_APPLIED` → Hidden: se l'editor ricarica il documento.

#### Tag suggestions (initial)
Mostra fino a cinque tag esistenti con il numero delle loro note: quelli il cui nome contiene il testo digitato, senza distinguere maiuscole e minuscole. Se il testo non è vuoto e nessun tag ha esattamente quel nome, aggiunge la voce «Crea #testo».
- `user.EDIT_NOTE_TEXT` → Tag suggestions: se si sta ancora scrivendo un tag. Aggiorna l'elenco.
- `user.EDIT_NOTE_TEXT` → Block menu: se non si sta più scrivendo un tag e la sezione di testo comincia con una barra.
- `user.OPEN_BLOCK_MENU` → Block menu: sotto la sezione di testo che ha il focus, anche se non comincia con una barra.
- `user.PICK_TAG_SUGGESTION` → Hidden: sostituisce il tag parziale con quello scelto, seguito da uno spazio.
- `user.CONFIRM_TAG_SUGGESTION` → Hidden: se c'è almeno un tag che corrisponde o è stato digitato del testo. Sceglie il primo tag che corrisponde, oppure crea il tag digitato se nessuno corrisponde.
- `user.DISMISS_TAG_SUGGESTIONS` → Hidden
- `user.LEAVE_NOTE_TEXT` → Hidden: se il focus lascia la sezione in cui si stava scrivendo il tag.

#### Block menu
Sotto la sezione di testo mostra le voci Checklist, Intestazione, Sottointestazione, Elenco, Numerato, Citazione e Tabella.
- `user.EDIT_NOTE_TEXT` → Tag suggestions: se si comincia a scrivere un tag.
- `user.PICK_BLOCK_MENU_ITEM` → Hidden
