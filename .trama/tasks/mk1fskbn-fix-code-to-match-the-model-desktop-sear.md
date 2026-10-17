---
column: done
technical: false
refs:
  - note-browser/Browsing
  - requirements/rules#note-browser
drift: null
proposal: null
agent: false
created: 2026-10-17T14:29:43.575Z
finished: 2026-10-17T14:39:33.759Z
---
# Fix code to match the Model: Desktop search field empties when the sidebar is hidden and shown during a search

Sul desktop, quando la barra laterale viene nascosta o mostrata mentre una ricerca è attiva (anche quando la larghezza della finestra la nasconde o la fa ricomparire), il campo di ricerca della lista compare vuoto mentre l'elenco resta filtrato dalla ricerca precedente. Il campo di ricerca della lista deve mostrare sempre il testo che sta filtrando l'elenco, anche dopo ogni cambio di visibilità della barra laterale, come già avviene per la schermata lista su mobile. Il testo di ricerca resta lo stesso: non viene azzerato e non cambia l'elenco.
