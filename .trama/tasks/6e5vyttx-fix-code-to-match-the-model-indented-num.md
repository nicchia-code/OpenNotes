---
column: done
technical: false
refs:
  - text-line/Numbered item/user.PRESS_TAB_IN_TEXT
  - requirements/rules#text-line
drift: null
proposal: null
agent: false
created: 2026-10-12T11:25:49.602Z
finished: 2026-10-12T13:56:11.892Z
---
# Fix code to match the Model: Indented numbered item loses its numbered type on Tab

Una voce numerata a cui si dà un Tab resta voce numerata: cambia solo il rientro, il numero resta e la voce continua a essere una voce numerata. Oggi appena la riga comincia con spazi perde il suo tipo e torna corpo: il tipo non viene più salvato, e chi esporta la nota in Markdown non la vede più come elenco numerato. Deve essere vero che Tab, Maiusc+Tab e Invio su una voce numerata rientrata lasciano il tipo numerato, come già per le voci puntate e le checklist.
