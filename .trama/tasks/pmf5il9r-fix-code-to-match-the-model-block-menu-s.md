---
column: done
technical: false
refs:
  - text-line/In document/user.PICK_BLOCK_MENU_ITEM
  - requirements/rules#text-line
drift: null
proposal: null
agent: false
created: 2026-10-12T11:25:49.401Z
finished: 2026-10-12T13:53:06.391Z
---
# Fix code to match the Model: Block menu style lands on the last line of the section, not on the line with the slash

Quando si sceglie una voce del menu rapido dopo una « / » scritta in una sezione di testo con altre righe sotto, lo stile (Intestazione, Sottointestazione, Checklist, Elenco, Numerato, Citazione) finisce sull'ultima riga della sezione invece che sulla riga dove era la « / ». Deve essere vero che: la « / » viene tolta dalla riga corrente e lo stile scelto si applica a quella stessa riga, mentre le altre righe della sezione restano com'erano. Il Modello dice che la voce toglie la barra dalla riga corrente e applica lo stile scelto; i Requisiti dicono che lo stile del menu rapido va alle righe selezionate.
