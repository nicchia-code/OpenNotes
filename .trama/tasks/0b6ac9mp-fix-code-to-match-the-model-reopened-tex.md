---
column: done
technical: false
refs:
  - text-line/Body/user.EDIT_NOTE_TEXT
  - text-line/Unchecked
  - text-line/Checked
  - requirements/rules#text-line
drift: null
proposal: null
agent: false
created: 2026-10-13T12:43:30.313Z
finished: 2026-10-13T13:15:37.299Z
---
# Fix code to match the Model: Reopened text with a checkbox not followed by a space becomes a checklist item

Quando una nota viene riaperta, una riga che comincia con una casella tra parentesi quadre non seguita da spazio (come «[ ]testo» o «[x]testo») diventa una voce di checklist, con il cerchio al posto della casella. Il Model dice che una riga diventa voce di checklist solo se la casella è seguita da spazio, come quando la si scrive: senza spazio la riga resta testo semplice. Il caricamento deve applicare la stessa regola della digitazione.
