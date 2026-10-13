---
column: done
technical: false
refs:
  - text-line/In document/user.TOGGLE_CHECKLIST
  - text-line/Monospace
  - requirements/rules#text-line
drift: null
proposal: null
agent: false
created: 2026-10-12T08:04:08.517Z
finished: 2026-10-12T10:32:32.201Z
---
# Fix code to match the Model: Checklist button on a monospace line keeps the fence marker

Premendo il pulsante checklist su una riga in monospazio, il segno di apertura « ``` » deve sparire e la riga diventa una voce da fare con il cerchio vuoto, con stile corpo. Il pulsante checklist toglie qualunque simbolo iniziale della riga prima di mettere il cerchio, anche il segno del monospazio, come gli altri stili. Oggi il segno resta nel testo dopo il cerchio e la riga non è più in monospazio né una voce pulita.
