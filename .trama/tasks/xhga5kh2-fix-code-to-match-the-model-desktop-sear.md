---
column: done
technical: false
refs:
  - note-browser/Browsing
  - desktop-layout/Auto mobile
drift: null
proposal: null
agent: false
created: 2026-10-17T18:16:52.662Z
finished: 2026-10-17T18:18:16.434Z
---
# Fix code to match the Model: Desktop search field is empty after switching from mobile to desktop layout during a search

Sul desktop, quando la finestra passa dall'interfaccia mobile a quella a colonne mentre una ricerca è attiva, il campo di ricerca della lista compare vuoto e l'elenco resta filtrato dalla ricerca precedente. Il campo deve mostrare sempre il testo che sta filtrando l'elenco, come già avviene nella schermata lista su mobile e come è stato richiesto per il cambio di visibilità della barra laterale. Il testo di ricerca non cambia: il passaggio di layout non lo azzera né lo modifica.
