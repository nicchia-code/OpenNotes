---
column: done
technical: false
refs:
  - export-markdown-share/Share sheet open
  - requirements/rules#export-markdown-share
drift: null
proposal: null
agent: false
created: 2026-10-13T10:39:54.914Z
finished: 2026-10-13T10:52:37.268Z
---
# Fix code to match the Model: Shared text has two blank lines between the title and a body that starts with a blank line

## What happens

Quando il corpo della nota inizia con una riga vuota (per esempio una nota in testo semplice con titolo, riga vuota e poi il testo, oppure una nota a blocchi con un paragrafo vuoto dopo il titolo), il testo condiviso ha due righe vuote tra il titolo e il contenuto invece di una.

## What should happen

Il testo condiviso deve essere il titolo, una sola riga vuota e poi il contenuto della nota convertito in Markdown, senza righe vuote iniziali aggiunte dalla preparazione del testo.

## Where in the code

lib/core/models/note_model.dart (toMarkdownBody: il corpo senza la riga del titolo conserva la riga vuota iniziale); lib/ui/notes_list/note_actions.dart (ramo della condivisione, testo = titolo + riga vuota + corpo)
