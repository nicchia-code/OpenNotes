---
column: done
technical: false
refs:
  - editor-suggestions/Shown/user.EDIT_NOTE_TEXT
  - editor-suggestions/Block menu
  - requirements/rules#editor-suggestions
drift: null
proposal: null
agent: false
created: 2026-10-17T19:22:52.855Z
finished: 2026-10-17T19:37:56.724Z
---
# Close the Block menu on key edits that drop the leading slash

Con il menu dei blocchi aperto sotto una sezione di testo, una modifica del testo fatta con i tasti (Invio, Tab o Backspace, per esempio su una voce di elenco, di numerato o di checklist) deve chiudere il menu quando la sezione non comincia più con una barra, esattamente come la digitazione. Oggi queste modifiche non passano dal percorso che legge il testo digitato: il menu aperto dal pulsante della barra o da una barra poi cancellata resta visibile sotto la sezione finché il focus non la lascia. Quando è fatto: dopo ogni modifica del testo della sezione, se la sezione non comincia con una barra e non si sta scrivendo un tag, il menu dei blocchi è chiuso.
