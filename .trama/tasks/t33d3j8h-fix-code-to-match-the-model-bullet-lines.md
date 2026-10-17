---
column: done
technical: false
refs:
  - text-line/Bulleted item
  - text-line/Numbered item
  - text-line/Quote
  - text-line/Monospace
  - requirements/rules#text-line
drift: null
proposal: null
agent: false
created: 2026-10-17T19:26:36.347Z
finished: 2026-10-17T19:37:13.765Z
---
# Fix code to match the Model: Bullet lines loaded from the block format ignore their indent level

Al caricamento dal formato a blocchi, una voce di elenco scritta con trattino o asterisco riceve sempre il simbolo del primo livello («•»), anche quando è rientrata. Deve invece ricevere il simbolo del proprio livello di rientro («◦», poi «▪», poi di nuovo «•»), come già avviene nel formato precedente e nel menu Aa. Lo stesso vale per un elenco salvato come voce puntata: oggi il simbolo resta al primo livello e il rientro finisce dopo il simbolo. Anche una citazione, una voce numerata o una riga monospazio salvate senza il loro segno nel testo, ma rientrate, ricevono il segno dopo il rientro: il rientro deve restare prima del simbolo. Fatto quando un elenco rientrato riaperto mostra il simbolo del suo livello e il rientro sta sempre prima del simbolo, in ogni formato in cui la nota può essere letta. Riferimenti: Model Bulleted item, Numbered item, Quote, Monospace; Requirement rules#text-line sul simbolo di elenco per livello. Vedi anche il Drift resolved 3ztwg41p, la cui decisione (il simbolo del livello) non è ancora rispettata dal caricamento a blocchi.
