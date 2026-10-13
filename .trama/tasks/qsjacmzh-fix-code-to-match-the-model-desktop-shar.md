---
column: done
technical: false
refs:
  - export-markdown-share/Idle/user.SHARE_NOTE
drift: null
proposal: null
agent: false
created: 2026-10-12T15:06:07.252Z
finished: 2026-10-12T16:27:27.473Z
---
# Fix code to match the Model: Desktop share sends the copy before the last typed text

Il menu azioni del desktop (la voce Condividi dal menu di una nota, anche dal pulsante ⋯ della barra superiore) passa al foglio di condivisione la copia della nota presente in memoria, senza consegnare prima il testo ancora in attesa nell'editor. Il testo digitato negli ultimi istanti può quindi mancare nel testo condiviso. L'esportazione su file già consegna il testo in attesa prima di procedere (task 43152a07). Quando il lavoro è finito, Condividi sul desktop deve produrre il Markdown di ciò che l'utente vede sullo schermo, anche mentre il salvataggio è in attesa, come l'esportazione. Lo stesso correttivo copre il menu del telefono descritto nel task etk6i6tj.
