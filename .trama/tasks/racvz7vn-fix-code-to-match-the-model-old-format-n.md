---
column: done
technical: false
refs:
  - text-line/Title
  - requirements/rules#text-line
drift: 4ecpyiam
proposal: null
agent: false
created: 2026-10-12T07:38:53.827Z
finished: 2026-10-12T07:55:34.801Z
---
# Fix code to match the Model: Old-format notes turn the first line after a table into a title

## What happens

Nel formato Markdown precedente, la prima riga di testo che segue una tabella diventa titolo grande e in grassetto, anche se nella nota non è la prima riga. Succede lo stesso a ogni sezione di testo che comincia dopo una tabella.

## What should happen

Il Model dice che al caricamento diventa titolo solo la prima riga significativa di una nota nel formato precedente, e la prima riga di una sezione che comincia con «# ». Una riga di testo che segue una tabella non è la prima riga della nota e non comincia con «# »: deve restare in stile corpo.

## Chosen option

**Titolo solo sulla prima riga della nota**

Il caricamento applica il titolo solo alla prima riga significativa dell'intera nota, come descrive il Model. Le righe che seguono una tabella restano corpo, e le righe che cominciano con «# » continuano a diventare intestazione o titolo come oggi. Costo: un controllo sulla posizione della riga nell'intera nota, da provare con note che hanno tabelle in mezzo.

## Where in the code

lib/ui/editor/notion_document_editor.dart, _parseContentToBlocks (ramo del testo nel formato precedente, riga iniziale di una sezione)
