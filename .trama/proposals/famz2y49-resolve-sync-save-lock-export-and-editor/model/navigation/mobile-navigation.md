# Mobile Navigation

La navigazione a schermate impilate dell'interfaccia stretta, in stile Note di iOS: Cartelle, lista delle note, editor della nota e tela di disegno. Ogni schermata aperta entra sopra la precedente e "indietro" (pulsante o gesto di scorrimento) torna a quella sotto. Le schermate leggono e cambiano la stessa selezione corrente (cartella, tag, cestino, ricerca, nota) dell'interfaccia desktop.

## States

### Inactive (initial)
L'interfaccia è desktop o non è ancora mostrata: non esiste una pila di schermate.
- `desktop-layout.SWITCHED_TO_MOBILE` → Notes list: la pila riparte sempre da capo, con la lista note in cima e le Cartelle sotto; la selezione corrente resta quella che era (al primo avvio Tutte le note).

### Active
È mostrata una pila di schermate.
- `desktop-layout.SWITCHED_TO_DESKTOP` → Inactive: la pila viene scartata con tutte le schermate aperte; un disegno non salvato va perso.

#### Notes list (initial)
Le note della selezione corrente, con le fissate in testa, il campo di ricerca, i tag da attivare o disattivare in più insieme, il conteggio e un menu che nel cestino permette di svuotarlo. Fissare o spostare nel cestino con lo scorrimento, filtrare per tag, cercare e svuotare il cestino non cambiano schermata.
- `user.NAVIGATE_BACK` → Folders
- `user.SELECT_NOTE` → Editing from list: seleziona la nota toccata e apre il suo editor; il ritorno indica "Cestino" nel cestino, i tag selezionati se c'è un filtro per tag, altrimenti "Note".
- `user.CREATE_NOTE` → Editing from list: solo se la selezione corrente non è il cestino, dove il pulsante non c'è; crea una nota nella selezione corrente e apre il suo editor, con ritorno "Note".
- `user.DUPLICATE_NOTE` → Editing from list: dal menu della pressione prolungata; a copia finita seleziona e apre la nota selezionata in quel momento, cioè la copia, o l'originale se lo sblocco richiesto per una nota protetta è stato annullato.

#### Folders
Tutte le note, Note, le cartelle dell'utente, i tag ed Eliminati di recente, ciascuno col suo conteggio. Creare, rinominare ed eliminare cartelle e aprire le impostazioni del cloud non cambiano schermata.
- `user.SELECT_ALL_NOTES` → Notes list: seleziona Tutte le note e apre la lista.
- `user.SELECT_FOLDER` → Notes list: seleziona la cartella Note o una dell'utente e apre la lista.
- `user.SELECT_TRASH` → Notes list: seleziona il cestino e apre la lista.
- `user.SELECT_TAG` → Notes list: apre la lista filtrata da quel tag; la selezione diventa solo quel tag e il filtro si applica una sola volta, anche se quel tag era già l'unico selezionato.
- `user.CREATE_NOTE` → Editing from folders: solo se la selezione corrente non è il cestino, dove il pulsante non c'è; crea una nota nella selezione corrente e apre subito il suo editor, con ritorno "Cartelle".

#### Editor from list
Editor a schermo intero della nota aperta dalla lista, con condivisione, protezione, menu azioni e strumenti sopra la tastiera. Con la nota protetta e non ancora sbloccata il pulsante del menu dei blocchi è disattivato, mentre gli altri strumenti sopra la tastiera (checklist, stile, tabella, disegno, foto) restano attivi e modificano il documento nascosto, come descritto nell'editor della nota. Spostare la nota in un'altra cartella, fissarla o ripristinarla dal cestino lasciano l'editor aperto; se la nota sparisce dai dati resta mostrata la sua ultima versione.

##### Editing from list (initial)
- `user.NAVIGATE_BACK` → Notes list
- `user.MOVE_NOTE_TO_TRASH` → Notes list: dal menu azioni, solo se la nota non è protetta oppure è già sbloccata in questa sessione; sposta la nota nel cestino, offre di annullare e chiude l'editor.
- `user.MOVE_NOTE_TO_TRASH` → Editing from list: dal menu azioni, se la nota è protetta e non ancora sbloccata in questa sessione; sposta la nota nel cestino e offre di annullare; l'editor resta aperto sul segnaposto «Questa nota è protetta» finché l'utente non torna indietro.
- `user.DELETE_NOTE_PERMANENTLY` → Notes list: dal menu azioni nel cestino, solo se l'utente conferma (dopo lo sblocco, se la nota è protetta) e la nota non è protetta oppure era già sbloccata in questa sessione; chiude l'editor.
- `user.DELETE_NOTE_PERMANENTLY` → Editing from list: dal menu azioni nel cestino, se l'utente conferma inserendo il PIN e la nota è protetta e non ancora sbloccata in questa sessione; l'editor resta aperto sul segnaposto «Questa nota è protetta» finché l'utente non torna indietro.
- `user.DUPLICATE_NOTE` → Editing from list: sostituisce l'editor con quello della nota selezionata a copia finita (la copia, o l'originale se lo sblocco è stato annullato), con lo stesso ritorno.
- `user.OPEN_DRAWING` → Drawing from list: anche se la nota è protetta e non ancora sbloccata in questa sessione; il disegno salvato viene inserito nel documento nascosto.

##### Drawing from list
Tela di disegno a schermo intero sopra l'editor.
- `drawing-canvas.DRAWING_SAVED` → Editing from list: la tela si chiude dopo che il disegno è stato salvato e inserito come immagine nella nota; se il salvataggio fallisce la tela resta aperta.
- `user.CANCEL_DRAWING` → Editing from list: chiude la tela senza inserire nulla.

#### Editor from folders
Editor a schermo intero di una nota appena creata dalle Cartelle, con gli stessi comandi dell'editor aperto dalla lista; sotto c'è direttamente la schermata Cartelle.

##### Editing from folders (initial)
- `user.NAVIGATE_BACK` → Folders
- `user.MOVE_NOTE_TO_TRASH` → Folders: dal menu azioni, solo se la nota non è protetta oppure è già sbloccata in questa sessione; sposta la nota nel cestino, offre di annullare e chiude l'editor.
- `user.MOVE_NOTE_TO_TRASH` → Editing from folders: dal menu azioni, se la nota è protetta e non ancora sbloccata in questa sessione; sposta la nota nel cestino e offre di annullare; l'editor resta aperto sul segnaposto «Questa nota è protetta» finché l'utente non torna indietro.
- `user.DELETE_NOTE_PERMANENTLY` → Folders: dal menu azioni nel cestino, solo se l'utente conferma (dopo lo sblocco, se la nota è protetta) e la nota non è protetta oppure era già sbloccata in questa sessione; chiude l'editor.
- `user.DELETE_NOTE_PERMANENTLY` → Editing from folders: dal menu azioni nel cestino, se l'utente conferma inserendo il PIN e la nota è protetta e non ancora sbloccata in questa sessione; l'editor resta aperto sul segnaposto «Questa nota è protetta» finché l'utente non torna indietro.
- `user.DUPLICATE_NOTE` → Editing from folders: sostituisce l'editor con quello della nota selezionata a copia finita (la copia, o l'originale se lo sblocco è stato annullato), con lo stesso ritorno.
- `user.OPEN_DRAWING` → Drawing from folders: anche se la nota è protetta e non ancora sbloccata in questa sessione; il disegno salvato viene inserito nel documento nascosto.

##### Drawing from folders
Tela di disegno a schermo intero sopra l'editor.
- `drawing-canvas.DRAWING_SAVED` → Editing from folders: la tela si chiude dopo che il disegno è stato salvato e inserito come immagine nella nota; se il salvataggio fallisce la tela resta aperta.
- `user.CANCEL_DRAWING` → Editing from folders: chiude la tela senza inserire nulla.
