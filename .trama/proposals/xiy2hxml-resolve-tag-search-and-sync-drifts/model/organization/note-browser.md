# Note Browser

Che cosa mostra l'elenco delle note: una raccolta (tutte le note, una cartella, il cestino) oppure uno o più tag, eventualmente ristretta da una ricerca testuale. Tiene anche l'elenco delle cartelle, l'elenco dei tag con il numero di note che li usano e i conteggi delle note per vista, cartella e cestino.

## States

### Loading (initial)
L'app si sta avviando e non ha ancora letto cartelle, tag e note.
- `operating-system.APP_LAUNCHED` → All notes: legge cartelle, tag e note, calcola i conteggi ed emette LIST_RELOADED.

### Browsing
L'elenco mostra le note della vista scelta, prima quelle fissate e poi dalla modifica più recente. Il testo di ricerca, se presente, restringe qualunque vista e resta attivo quando si cambia vista; creando una nota si svuota, così la nota nuova compare nell'elenco. Ogni cambio di vista, di tag o di ricerca ricarica l'elenco ed emette LIST_RELOADED; dopo ogni ricarica i conteggi vengono ricalcolati. L'elenco viene ricaricato anche dopo ogni modifica di una nota (creazione, salvataggio, fissaggio, blocco, cestino, ripristino, spostamento, eliminazione), quando l'utente crea, rinomina o elimina una cartella, al termine di una sincronizzazione e a ogni cambiamento ricevuto dal cloud. L'elenco dei tag invece si aggiorna solo all'avvio, alla creazione, duplicazione o salvataggio di una nota, quando una nota va nel cestino, ne viene ripristinata o viene spostata in un'altra cartella, al termine di una sincronizzazione e a ogni cambiamento ricevuto dal cloud.
- `user.SELECT_ALL_NOTES` → All notes: svuota la selezione dei tag.
- `user.SELECT_FOLDER` → Folder: svuota la selezione dei tag; vale sia per la cartella "Note" sia per le cartelle utente.
- `user.SELECT_TRASH` → Trash: svuota la selezione dei tag.

#### All notes (initial)
Tutte le note non nel cestino, di qualunque cartella.
- `user.SELECT_TAG` → Tag filter: la selezione diventa solo quel tag.
- `user.TOGGLE_TAG` → Tag filter: il tag viene aggiunto alla selezione.
- `user.CHANGE_SEARCH_QUERY` → All notes: l'elenco viene filtrato con il nuovo testo.

#### Folder
Le note non nel cestino di una sola cartella.
- `folder.DELETED` → All notes: solo se la cartella eliminata è quella mostrata.
- `user.SELECT_TAG` → Tag filter: si passa a cercare nelle note di tutte le cartelle; la selezione diventa solo quel tag.
- `user.TOGGLE_TAG` → Tag filter: si passa a cercare nelle note di tutte le cartelle; il tag viene aggiunto alla selezione.
- `user.CHANGE_SEARCH_QUERY` → Folder: l'elenco viene filtrato con il nuovo testo.

#### Tag filter
Le note non nel cestino, di qualunque cartella, che hanno tutti i tag selezionati.
- `user.SELECT_TAG` → All notes: se era selezionato soltanto quel tag, dalla barra laterale, da un'etichetta di una nota o dall'editor; la selezione si svuota.
- `user.SELECT_TAG` → Tag filter: negli altri casi la selezione diventa solo quel tag; dalla schermata Cartelle su mobile succede sempre, anche se quel tag era già l'unico selezionato, e il filtro resta.
- `user.TOGGLE_TAG` → Tag filter: il tag viene aggiunto se manca o tolto se c'è, purché nella selezione ne resti almeno uno.
- `user.TOGGLE_TAG` → All notes: se viene tolto l'ultimo tag selezionato.
- `user.CLEAR_TAG_FILTER` → All notes: svuota la selezione dei tag.
- `user.CHANGE_SEARCH_QUERY` → Tag filter: l'elenco viene filtrato con il nuovo testo.

#### Trash
Le note nel cestino di tutte le cartelle.
- `user.SELECT_TAG` → Tag filter: si esce dal cestino e si guardano le note non nel cestino di tutte le cartelle; la selezione diventa solo quel tag.
- `user.TOGGLE_TAG` → Tag filter: si esce dal cestino; il tag viene aggiunto alla selezione.
- `user.CHANGE_SEARCH_QUERY` → Trash: l'elenco viene filtrato con il nuovo testo.

## Events

### LIST_RELOADED
Emesso ogni volta che l'elenco delle note della vista viene ricaricato: all'avvio, a ogni cambio di vista, di tag o di ricerca, dopo ogni modifica di una nota o di una cartella, al termine di una sincronizzazione e a ogni cambiamento ricevuto dal cloud.
