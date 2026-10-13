---
column: done
technical: false
refs:
  - note-selection/Note selected/user.MOVE_NOTE_TO_TRASH
  - requirements/rules#note-selection
drift: null
proposal: null
agent: false
created: 2026-10-13T10:50:47.864Z
finished: 2026-10-13T10:53:22.599Z
---
# Fix code to match the Requirements: Trash move selects the first note when the neighbour disappears during the move

Quando una nota viene spostata nel cestino, la selezione passa alla nota che la seguiva nell'elenco, o alla precedente se era l'ultima. Oggi, se la nota che deve essere selezionata sparisce dall'elenco prima che l'elenco venga ricaricato (per esempio perché un cambiamento arrivato dal cloud la rimuove mentre lo spostamento è in corso), l'app seleziona la prima nota dell'elenco invece della precedente. Il Requirement prevede che si selezioni la nota che seguiva, altrimenti la precedente, purché sia ancora nell'elenco ricaricato. Correggere in modo che, in questo caso, la selezione vada alla nota che precedeva quella spostata; la prima nota resta solo come ripiego quando non ne esiste nessuna delle due nell'elenco ricaricato e l'elenco non è vuoto. Il Model non cambia.
