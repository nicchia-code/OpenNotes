---
column: done
technical: false
refs:
  - text-line/In document/user.TOGGLE_CHECKLIST
  - requirements/rules#text-line
drift: null
proposal: null
agent: false
created: 2026-10-13T14:25:47.093Z
finished: 2026-10-13T14:44:55.054Z
---
# Fix code to match the Requirements: Checklist button keeps a second leading symbol of the line

Il pulsante checklist, premuto su una riga che non è ancora una voce di checklist, mette il cerchio vuoto e toglie il primo simbolo iniziale, ma un secondo simbolo iniziale (per esempio un elenco puntato con una citazione dopo) resta nel testo: «• > x» diventa «○ > x». Quando il pulsante mette il cerchio deve togliere tutti i prefissi iniziali della riga, come fa lo stile scelto dal menu Aa, lasciando solo il testo e il rientro. Fatto: su una riga con più simboli iniziali il pulsante lascia la riga come «○ x», e le righe con un solo simbolo o con nessuno non cambiano.
