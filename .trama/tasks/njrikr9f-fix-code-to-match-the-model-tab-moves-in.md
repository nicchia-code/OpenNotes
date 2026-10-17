---
column: done
technical: false
refs:
  - text-line/Body/user.PRESS_TAB_IN_TEXT
drift: null
proposal: null
agent: false
created: 2026-10-17T12:50:50.275Z
finished: 2026-10-17T13:46:14.981Z
---
# Fix code to match the Model: Tab moves inline formatting twice

Premere Tab o Maiusc+Tab su una o più righe di corpo, di voce o di citazione non deve spostare la formattazione dei caratteri (grassetto, corsivo, sottolineato, barrato). Ogni intervallo di formattazione, sulla riga modificata e sulle righe sotto, deve restare sugli stessi caratteri e spostarsi solo della lunghezza dei due spazi aggiunti o tolti, una sola volta. Oggi le righe sotto la riga modificata si spostano di due caratteri in più e la formattazione della riga stessa si allarga sul testo della riga successiva. Requisito: intervalli di formattazione come posizioni di carattere, Requirement data editor.
