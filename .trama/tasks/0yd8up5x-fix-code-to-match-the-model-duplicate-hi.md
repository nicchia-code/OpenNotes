---
column: done
technical: false
refs:
  - note-selection/Note selected/user.DUPLICATE_NOTE
  - requirements/rules#note-selection
drift: null
proposal: null
agent: false
created: 2026-10-12T15:08:12.708Z
finished: 2026-10-12T16:31:39.965Z
---
# Fix code to match the Model: Duplicate hidden by an active search leaves no note open

Duplicare una nota con una ricerca attiva seleziona la copia, ma la copia può non rientrare nella ricerca: non compare nell'elenco e l'editor resta vuoto, mentre il Model dice che la nota selezionata è sempre una della vista corrente. Quando la copia viene creata deve essere visibile nell'elenco e aperta nell'editor, come già avviene per la nota nuova. Vedi la Task lq4kxj06 (creazione con ricerca attiva) e il Drift s1joyu64 ancora aperto sulla stessa scelta.
