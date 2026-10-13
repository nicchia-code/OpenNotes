---
column: done
technical: false
refs:
  - text-line/Bulleted item
  - text-line/Checklist item
drift: null
proposal: null
agent: false
created: 2026-10-13T05:25:26.450Z
finished: 2026-10-13T05:35:50.073Z
---
# Backspace after an unindented bullet or checklist symbol removes the symbol and its space

Con il cursore subito dopo il simbolo di una voce puntata o da fare non rientrata, ma prima dello spazio che lo segue, il Backspace oggi toglie solo il simbolo e lascia uno spazio all'inizio del testo. Il Model dice che il simbolo viene tolto e il testo resta: deve sparire anche lo spazio, come già accade quando il cursore è dopo lo spazio. Vale per la voce puntata e per la voce di checklist, con cerchio vuoto o pieno.
