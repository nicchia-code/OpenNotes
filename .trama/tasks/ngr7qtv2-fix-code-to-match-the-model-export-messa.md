---
column: done
technical: false
refs:
  - export-markdown-file/Choosing destination
drift: null
proposal: null
agent: false
created: 2026-10-17T12:42:11.799Z
finished: 2026-10-17T13:43:22.359Z
---
# Fix code to match the Model: Export message shows the proposed name when the saved file name is not in the URI

Quando il sistema restituisce dopo il salvataggio un URI senza il nome del file (per esempio un identificatore opaco, come accade con alcuni provider Android), il messaggio di esportazione mostra il nome proposto e non il nome con cui il file è stato davvero scritto, anche se l'utente lo ha cambiato nella finestra di salvataggio. Atteso: alla chiusura della finestra con una posizione scelta, il messaggio riporta il nome del file esportato, letto dal sistema anche quando l'URI non lo contiene; se il nome non è disponibile il messaggio resta comunque coerente con il file scritto.
