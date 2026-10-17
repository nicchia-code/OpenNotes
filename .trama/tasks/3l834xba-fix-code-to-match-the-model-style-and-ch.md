---
column: done
technical: false
refs:
  - text-line/In document/user.SET_TEXT_STYLE
drift: null
proposal: null
agent: false
created: 2026-10-17T12:50:50.771Z
finished: 2026-10-17T13:46:21.648Z
---
# Fix code to match the Model: Style and checklist prefixes misplace inline formatting

Scegliere uno stile dal menu Aa o dal menu rapido, e premere il pulsante checklist, deve togliere i simboli iniziali delle righe selezionate e aggiungere il nuovo simbolo senza spostare la formattazione dei caratteri. Grassetto, corsivo, sottolineato e barrato restano sugli stessi caratteri della riga e delle righe sotto, spostati solo della lunghezza dei simboli tolti o aggiunti, una sola volta. Oggi il simbolo tolto sposta due volte la formattazione delle righe sotto, e il simbolo aggiunto non sposta la formattazione che sta sulla stessa riga.
