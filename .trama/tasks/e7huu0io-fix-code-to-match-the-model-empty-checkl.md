---
column: done
technical: false
refs:
  - export-pdf/Idle/user.EXPORT_NOTE_AS_PDF
  - requirements/rules#export-pdf
drift: null
proposal: null
agent: false
created: 2026-10-12T11:20:43.409Z
finished: 2026-10-12T13:56:43.120Z
---
# Fix code to match the Model: Empty checklist, bullet or heading line loses its marker in the PDF export

Nel PDF di una nota una riga di elenco o di intestazione senza testo perde il suo segno. Una casella vuota («- [ ]») compare come punto elenco con la scritta «[ ]»; un punto vuoto compare come testo «-»; un'intestazione vuota compare come testo «#». Il Requirement vuole il cerchio per la casella, il punto elenco per «- » e il titolo per «# ».
