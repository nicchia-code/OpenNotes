---
column: done
technical: false
refs:
  - note/Active
  - requirements/rules#note
drift: null
proposal: null
agent: false
created: 2026-10-12T15:08:37.986Z
finished: 2026-10-12T16:37:43.237Z
---
# Fix code to match the Requirements: Note preview cut at 90 code units, the Requirement counts characters

L'anteprima di una nota si interrompe quando il testo supera 90 unità di codice invece che 90 caratteri. Il Requirement dice che l'anteprima si ferma appena il testo supera 90 caratteri: un carattere fuori dal piano base (per esempio un'emoji) conta come uno. Quando il lavoro è finito, l'anteprima dei documenti a blocchi e dei testi semplici conta caratteri interi, senza spezzarne nessuno, come già richiesto per il titolo (Task qcc6eseh).
