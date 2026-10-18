# Editor suggestions

I menu che compaiono mentre si scrive nell'editor: i suggerimenti di tag e il menu rapido dei blocchi, aperto digitando una barra a inizio sezione oppure dal suo pulsante sulla barra sopra la tastiera del telefono. I menu seguono allo stesso modo le modifiche del testo fatte dall'editor con Tab, Invio e Backspace: le condizioni sono quelle della digitazione, valutate sul testo che il tasto lascia.

## States

### Hidden (initial)
Nessun menu è aperto.
- `user.EDIT_NOTE_TEXT` → Tag suggestions: se il testo prima del cursore finisce con un cancelletto, all'inizio della sezione o dopo uno spazio di qualunque tipo, compresi la tabulazione e l'a capo (quindi anche a inizio riga), seguito solo da lettere e cifre di qualunque alfabeto, trattini o trattini bassi (anche da nessun carattere).
- `user.EDIT_NOTE_TEXT` → Block menu: se non si sta scrivendo un tag e la sezione di testo comincia con una barra.
- `user.PRESS_TAB_IN_TEXT` → Tag suggestions: se il tasto cambia il testo della sezione e dopo il tasto si sta scrivendo un tag, alle stesse condizioni della digitazione (per esempio Maiuscole+Tab toglie il simbolo di elenco davanti a «#lav»).
- `user.PRESS_TAB_IN_TEXT` → Block menu: se il tasto cambia il testo della sezione, dopo il tasto non si sta scrivendo un tag e la sezione di testo comincia con una barra (per esempio Maiuscole+Tab toglie il rientro davanti alla barra).
- `user.PRESS_ENTER_IN_TEXT` → Tag suggestions: alle stesse condizioni di Tab.
- `user.PRESS_ENTER_IN_TEXT` → Block menu: alle stesse condizioni di Tab.
- `user.PRESS_BACKSPACE_IN_TEXT` → Tag suggestions: alle stesse condizioni di Tab.
- `user.PRESS_BACKSPACE_IN_TEXT` → Block menu: alle stesse condizioni di Tab.
- `user.OPEN_BLOCK_MENU` → Block menu: sotto la sezione di testo che ha il focus, anche se non comincia con una barra.

### Shown
- `user.EDIT_NOTE_TEXT` → Hidden: se non si sta più scrivendo un tag e la sezione di testo non comincia con una barra.
- `user.PRESS_TAB_IN_TEXT` → Hidden: se il tasto non conferma un suggerimento di tag, cambia il testo della sezione e, come dopo la digitazione, non si sta più scrivendo un tag e la sezione di testo non comincia con una barra (per esempio Tab aggiunge il rientro davanti alla barra).
- `user.PRESS_ENTER_IN_TEXT` → Hidden: alle stesse condizioni di Tab.
- `user.PRESS_BACKSPACE_IN_TEXT` → Hidden: alle stesse condizioni di Tab.
- `note-selection.SELECTED_NOTE_CHANGED` → Hidden
- `sync-run.CLOUD_NOTE_APPLIED` → Hidden: se l'editor ricarica il documento.
- `realtime-channel.CLOUD_NOTE_APPLIED` → Hidden: se l'editor ricarica il documento.

#### Tag suggestions (initial)
Mostra fino a cinque tag esistenti con il numero delle loro note: quelli il cui nome contiene il testo digitato, senza distinguere maiuscole e minuscole. Se il testo non è vuoto e nessun tag ha quel nome, senza distinguere maiuscole e minuscole, aggiunge la voce «Crea #testo».
- `user.EDIT_NOTE_TEXT` → Tag suggestions: se si sta ancora scrivendo un tag. Aggiorna l'elenco.
- `user.EDIT_NOTE_TEXT` → Block menu: se non si sta più scrivendo un tag e la sezione di testo comincia con una barra.
- `user.PRESS_TAB_IN_TEXT` → Tag suggestions: se il tasto non conferma un suggerimento, cambia il testo della sezione e dopo il tasto si sta ancora scrivendo un tag. Aggiorna l'elenco.
- `user.PRESS_TAB_IN_TEXT` → Block menu: se il tasto non conferma un suggerimento, cambia il testo della sezione, dopo il tasto non si sta più scrivendo un tag e la sezione di testo comincia con una barra.
- `user.PRESS_ENTER_IN_TEXT` → Tag suggestions: alle stesse condizioni di Tab. Aggiorna l'elenco.
- `user.PRESS_ENTER_IN_TEXT` → Block menu: alle stesse condizioni di Tab.
- `user.PRESS_BACKSPACE_IN_TEXT` → Tag suggestions: se il tasto cambia il testo della sezione e dopo il tasto si sta ancora scrivendo un tag. Aggiorna l'elenco.
- `user.PRESS_BACKSPACE_IN_TEXT` → Block menu: se il tasto cambia il testo della sezione, dopo il tasto non si sta più scrivendo un tag e la sezione di testo comincia con una barra.
- `user.OPEN_BLOCK_MENU` → Block menu: sotto la sezione di testo che ha il focus, anche se non comincia con una barra.
- `user.PICK_TAG_SUGGESTION` → Hidden: sostituisce il tag parziale con quello scelto, seguito da uno spazio.
- `user.CONFIRM_TAG_SUGGESTION` → Hidden: se c'è almeno un tag che corrisponde o è stato digitato del testo. Sceglie il primo tag che corrisponde, oppure crea il tag digitato se nessuno corrisponde.
- `user.DISMISS_TAG_SUGGESTIONS` → Hidden
- `user.LEAVE_NOTE_TEXT` → Hidden: se il focus lascia la sezione in cui si stava scrivendo il tag.

#### Block menu
Sotto la sezione di testo mostra le voci Checklist, Intestazione, Sottointestazione, Elenco, Numerato, Citazione e Tabella.
- `user.EDIT_NOTE_TEXT` → Tag suggestions: se si comincia a scrivere un tag.
- `user.PRESS_TAB_IN_TEXT` → Tag suggestions: se il tasto cambia il testo della sezione e dopo il tasto si comincia a scrivere un tag.
- `user.PRESS_ENTER_IN_TEXT` → Tag suggestions: alle stesse condizioni di Tab.
- `user.PRESS_BACKSPACE_IN_TEXT` → Tag suggestions: alle stesse condizioni di Tab.
- `user.PICK_BLOCK_MENU_ITEM` → Hidden
- `user.LEAVE_NOTE_TEXT` → Hidden: se il focus lascia la sezione di testo sotto cui è aperto il menu.
