---
status: resolved
resolution: proposal
refs:
  - editor-suggestions/Tag suggestions/user.EDIT_NOTE_TEXT
  - requirements/rules#editor-suggestions
proposal: null
task: null
origin: null
previous: rf3tlk07
critical: false
option: null
note: null
resolvedBy: tqf85in9
created: 2026-10-17T17:17:32.191Z
---
# Tag suggestions open after a line break again

## What happens

Il menu dei tag compare anche quando il cancelletto è digitato all'inizio di una riga nuova dentro la sezione, cioè dopo un **a capo** e non dopo uno spazio. Il Drift rf3tlk07 era stato risolto con una correzione del codice, ma nel codice la differenza è ancora presente.

## What should happen

Il Modello (stato Tag suggestions) e il Requisito dicono che il cancelletto avvia un tag **solo all'inizio della sezione o dopo uno spazio**. Un a capo non è citato né come inizio né come spazio.

## Fix options

### Aprire il menu solo dopo uno spazio

Il menu compare solo all'inizio della sezione o dopo uno spazio, come scritto nel Modello e nel Requisito, che restano come sono. Un tag digitato a inizio riga resta un tag e viene salvato, ma senza suggerimenti. Costo: a inizio riga l'esperienza diventa diversa da quella delle note, che riconoscono il tag anche dopo un a capo.

### Aprire il menu solo dopo uno spazio vero

Come la prima via, ma la tabulazione non conta come spazio: il menu compare solo dopo un carattere di spazio. Il Modello e il Requisito restano come sono. Costo: dopo una tabulazione il menu non compare, mentre oggi compare; è un caso raro, ma il comportamento cambia anche lì.

## Where in the code

lib/ui/editor/notion_document_editor.dart, _handleTextChanged: il riconoscimento del cancelletto prima del cursore usa lo spazio generico, che comprende anche l'a capo
