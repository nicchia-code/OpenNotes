---
column: done
technical: false
refs:
  - editor-suggestions/Tag suggestions/user.EDIT_NOTE_TEXT
drift: null
proposal: null
agent: false
created: 2026-10-12T14:48:51.122Z
finished: 2026-10-12T16:26:47.444Z
---
# Fix code to match the Model: Tag letters of any alphabet are not recognised

## Cosa succede

Il riconoscimento dei tag accetta solo lettere latine (accentate incluse), cifre, «_» e «-» (Note.tagNameChar in lib/core/models/note_model.dart, usata anche da lib/ui/editor/notion_document_editor.dart e dai controller di testo). Una parola in cirillico, greco o con ideogrammi preceduta da «#» non diventa tag: non compare tra i suggerimenti, nell'elenco e nel filtro, e non viene evidenziata nel testo né nelle celle delle tabelle.

## Cosa deve succedere

Il Model (editor-suggestions, Tag suggestions) e i Requirement (rules editor, notes, organization) dicono che un tag è «#» seguito da lettere e cifre di qualunque alfabeto, «_» o «-». La regola è stata allineata a questa forma con la proposal ccg944lf, che sostituisce la scelta di tag solo latini.

Fatto quando: un «#» seguito da parole in cirillico, greco o ideogrammi diventa tag nel menu dei suggerimenti, nel salvataggio, nell'elenco e nel filtro, e nell'evidenziazione; lettere e cifre seguono la stessa definizione in tutti questi punti.
