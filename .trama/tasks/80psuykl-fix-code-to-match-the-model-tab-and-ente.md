---
column: done
technical: false
refs:
  - text-line/Body/user.PRESS_TAB_IN_TEXT
  - text-line/Bulleted item
  - requirements/rules#text-line
drift: null
proposal: null
agent: false
created: 2026-10-12T08:04:08.653Z
finished: 2026-10-12T10:34:36.515Z
---
# Fix code to match the Model: Tab and Enter treat a dash or asterisk without a space as a list item

Una riga di testo normale che comincia con un trattino, un asterisco o un simbolo di elenco non seguito da spazio, per esempio «-5 gradi», non è una voce puntata. Tab deve solo aggiungere due spazi di rientro senza togliere il carattere, e Invio in fondo alla riga non deve creare una voce puntata sotto. Una voce puntata richiede il simbolo seguito da uno spazio.
