---
column: done
technical: false
refs:
  - text-line/In document/user.PRESS_BACKSPACE_IN_TEXT
  - text-line/Removed
  - requirements/rules#text-line
drift: null
proposal: null
agent: false
created: 2026-10-12T10:51:17.532Z
finished: 2026-10-12T11:07:34.607Z
---
# Fix code to match the Requirements: Line joined into a section ending with an empty styled line keeps the wrong style

Quando la prima riga di una sezione di testo viene unita alla sezione precedente con Backspace all'inizio, la riga che resta prende lo stile secondo la regola delle modifiche: se la riga unita ha uno stile, quello vince sulla riga vuota in fondo alla sezione precedente; se la riga unita è in corpo, la riga vuota tiene il proprio stile. Oggi la riga vuota conserva sempre il suo stile, quindi un'intestazione vuota in fondo alla sezione precedente trasforma in intestazione una riga unita in corpo. Se la sezione precedente è vuota, la riga unita in corpo deve lasciare il proprio stile alla riga che resta, ma oggi lo perde.
