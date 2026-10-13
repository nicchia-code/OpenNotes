---
status: resolved
resolution: fix-code
refs:
  - editor-suggestions/Tag suggestions/user.EDIT_NOTE_TEXT
  - requirements/rules#editor-suggestions
proposal: null
task: htcwvbld
origin: null
critical: false
option: 1
note: null
resolvedBy: psazi867
created: 2026-10-12T16:47:14.386Z
---
# Tag suggestions open after a line break, the Model says after a space

## What happens

Il menu dei tag compare anche quando il cancelletto è digitato all'inizio di una riga nuova dentro la sezione, cioè dopo un **a capo** e non dopo uno spazio.

## What should happen

Il Modello e il Requisito dicono che il cancelletto avvia un tag **all'inizio della sezione o dopo uno spazio**. Un a capo non è citato, né come inizio né come spazio.

## Fix options

### Contare anche l'a capo

Il menu compare anche dopo un a capo, come oggi. Il Modello e il Requisito vanno completati con questa regola, così come le note già riconoscono un tag a inizio riga. Costo: il menu si apre più spesso, anche quando l'utente va a capo e scrive un cancelletto per un'altra ragione.

### Solo dopo uno spazio

Il menu compare solo all'inizio della sezione o dopo uno spazio, come scritto. Un tag digitato a inizio riga non mostra suggerimenti, ma viene comunque salvato come tag. Costo: il codice cambia e l'esperienza a inizio riga diventa diversa da quella delle note.

## Where in the code

lib/ui/editor/notion_document_editor.dart (_handleTextChanged)
