---
column: done
technical: false
refs:
  - text-line/Body/user.EDIT_NOTE_TEXT
  - text-line/Heading
  - requirements/rules#text-line
drift: null
proposal: null
agent: false
created: 2026-10-12T11:25:49.792Z
finished: 2026-10-12T14:02:08.987Z
---
# Fix code to match the Model: Indented « # » line becomes a heading

Una riga che, dopo degli spazi di rientro, comincia con « # », « ## » o « ### » oggi appare come intestazione e, quando la nota viene riaperta, diventa intestazione senza più il rientro. Deve essere vero che la riga diventa intestazione solo se comincia con il segno: una riga rientrata resta corpo, con il rientro e il testo com'erano, anche alla riapertura della nota.
