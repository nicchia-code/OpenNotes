# Note Selection

La nota selezionata tra quelle della vista corrente: è quella evidenziata nell'elenco e aperta nell'editor.

## States

### No note (initial)
Nessuna nota è selezionata: le note non sono ancora state caricate oppure l'elenco è vuoto.
- `note-browser.LIST_RELOADED` → Note selected: solo se l'elenco non è vuoto; viene selezionata la prima nota, anche su mobile.
- `user.SELECT_NOTE` → Note selected
- `user.CREATE_NOTE` → Note selected: viene selezionata la nuova nota.
- `user.DUPLICATE_NOTE` → Note selected: viene selezionata la copia.

### Note selected
Una nota della vista corrente è selezionata.
- `user.SELECT_NOTE` → Note selected: viene selezionata la nota scelta nell'elenco.
- `user.CREATE_NOTE` → Note selected: viene selezionata la nuova nota.
- `user.DUPLICATE_NOTE` → Note selected: viene selezionata la copia.
- `note-browser.LIST_RELOADED` → Note selected: se la nota selezionata non è più nell'elenco e l'elenco non è vuoto, viene selezionata la prima nota; altrimenti la selezione resta com'è.
- `note-browser.LIST_RELOADED` → No note: se la nota selezionata non è più nell'elenco e l'elenco è vuoto.
- `user.MOVE_NOTE_TO_TRASH` → Note selected: dopo la ricarica viene selezionata la nota che seguiva quella spostata nell'elenco, o la precedente se era l'ultima, anche quando la nota spostata non era quella selezionata.
- `user.MOVE_NOTE_TO_TRASH` → No note: se nell'elenco non resta nessuna nota.

## Events

### SELECTED_NOTE_CHANGED
Emesso ogni volta che cambia la nota selezionata: scelta dell'utente, nuova nota o copia, selezione automatica della prima nota dopo una ricarica, nota vicina dopo lo spostamento nel cestino, oppure nessuna nota.
