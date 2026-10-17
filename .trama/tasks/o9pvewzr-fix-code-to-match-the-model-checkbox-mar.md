---
column: done
technical: false
refs:
  - text-line/Body/user.EDIT_NOTE_TEXT
drift: null
proposal: null
agent: false
created: 2026-10-17T12:50:52.250Z
finished: 2026-10-17T13:45:57.696Z
---
# Fix code to match the Model: Checkbox marker without a space is treated as a checklist item

Una riga che comincia con «[ ]» o «[x]» non seguito da spazio (per esempio «[ ]testo») resta testo semplice, come già accade al caricamento. Invio, Tab, Backspace, il pulsante checklist e il tocco sulla casella non devono trattarla come voce di checklist: Invio non deve creare una voce «○ » sotto, Tab deve aggiungere solo lo spazio di rientro al testo, Backspace subito dopo la casella non deve cancellarla, il pulsante checklist deve mettere «○ » davanti senza considerare la casella come voce già esistente, e il tocco sulla casella non deve spuntarla. La regola è la stessa della digitazione: la casella diventa cerchio solo se seguita da spazio.
