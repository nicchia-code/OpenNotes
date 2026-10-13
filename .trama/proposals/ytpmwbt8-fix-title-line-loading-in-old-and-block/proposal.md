---
status: approved
kind: resolution
automatic: true
drifts:
  - drift: hah0a4q5
    decision: fix-code
    option: 1
  - drift: gn67rtks
    decision: fix-code
    option: 1
  - drift: 6csmm45w
    decision: fix-code
    option: 1
base: {}
delete: []
created: 2026-10-12T08:51:43.342Z
---
# Fix title line loading in old and block formats

Risoluzione automatica dei Drift sullo stile Titolo al caricamento delle note:
- D3 – Old-format note: first line with ## or ### takes Heading 2 or 3 instead of Title: correzione nel codice (opzione 1, la prima riga significativa diventa sempre Titolo e il prefisso viene tolto).
- D5 – Old-format title line keeps its list symbol and Enter below it makes a list item: correzione nel codice (opzione 1, il simbolo iniziale viene tolto quando la riga riceve il Titolo al caricamento).
- D6 – Block-format heading after an empty text line that follows a table is Heading 1, not Title: correzione nel codice (opzione 1, il conteggio delle righe riparte a ogni tabella).
