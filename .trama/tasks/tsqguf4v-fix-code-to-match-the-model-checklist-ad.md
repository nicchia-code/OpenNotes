---
column: done
technical: false
refs:
  - note-editor/Open/user.TOGGLE_CHECKLIST
  - requirements/data#note-editor
drift: null
proposal: null
agent: false
created: 2026-10-12T11:38:41.464Z
finished: 2026-10-12T13:53:25.358Z
---
# Fix code to match the Model: Checklist added above a formatted line shifts that line's formatting twice

Il Model dice che il comando alterna la voce di checklist sulla riga del cursore, oppure la crea, e salva subito (note-editor, Open, user.TOGGLE_CHECKLIST). Il Requirement dati definisce gli intervalli di formattazione come posizioni di carattere: quando si aggiunge il prefisso di checklist a una riga, la formattazione delle righe successive deve restare sugli stessi caratteri.

Nel codice invece, quando la riga del cursore non ha ancora la checklist, la creazione passa da applyLinePrefix nel controller di testo. Lì gli intervalli che iniziano dopo la fine della riga vengono già spostati a mano di lunghezza del prefisso, e poi il listener di cambio testo del controller li sposta di nuovo con la stessa differenza. Il risultato: grassetto, corsivo, sottolineato e barrato delle righe sotto la riga modificata si spostano di due caratteri (il doppio del prefisso «○ ») invece di restare dove sono. Il dato salvato risulta quindi diverso da quello che l'utente vedeva.

Da correggere: fare in modo che l'aggiunta del prefisso sposti ogni intervallo di formattazione una sola volta. Poiché la causa sta nel metodo condiviso applyLinePrefix, correggere lì (non solo nel ramo della checklist) e verificare che gli altri comandi che lo usano (elenchi puntati, numerati) non abbiano lo stesso effetto. Il comportamento per il testo della riga del cursore e per il cambio ○ ↔ ● non cambia.
