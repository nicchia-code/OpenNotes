---
column: done
technical: true
refs:
  - requirements/rules#note-editor
drift: s6goeoj0
proposal: null
agent: false
created: 2026-10-12T07:38:53.781Z
finished: 2026-10-12T07:49:13.619Z
---
# Fix code to match the Requirements: Arrow keys do not cross tables and images

## What happens

All'inizio di una sezione di testo dopo una tabella o un'immagine, la freccia su non porta nella parte precedente: il tasto viene assorbito e il cursore resta fermo. Lo stesso accade con la freccia giù alla fine di una sezione che precede una tabella o un'immagine.

## What should happen

La Requirement dice che la freccia su all'inizio di una parte passa alla fine della parte precedente, e la freccia giù alla fine passa all'inizio della successiva. Tabelle e immagini sono parti a sé, quindi il passaggio deve funzionare anche verso di loro.

## Chosen option

**Far entrare il cursore nella tabella o nell'immagine**

La freccia su porta nell'ultima cella della tabella precedente, la freccia giù nella prima cella di quella successiva. Un'immagine non ha celle: il cursore la salta e va alla sezione di testo oltre. Costo: la navigazione va scritta per ogni tipo di parte.

## Where in the code

lib/ui/editor/notion_document_editor.dart: _handleKeyEvent, frecce su e giù; tabelle e immagini non hanno un nodo di focus, quindi la richiesta di focus non ha effetto.
