---
column: done
technical: false
refs:
  - text-line/Quote
  - text-line/Monospace
  - text-line/Numbered item
  - text-line/Body/user.EDIT_NOTE_TEXT
drift: null
proposal: null
agent: false
created: 2026-10-12T10:51:17.350Z
finished: 2026-10-12T10:55:31.058Z
---
# Fix code to match the Model: Typed quote, monospace and numbered lines reload with the symbol doubled

Una riga digitata con «> », con tre apici inversi o con un numero seguito da un punto diventa citazione, monospazio o voce numerata e il segno resta nel testo. Oggi, quando la nota viene riaperta, la stessa riga ricompare con il segno raddoppiato («> > testo», «``` ``` testo», «1. 1. testo»): il tipo memorizzato della riga aggiunge di nuovo il segno a un testo che lo contiene già. Al caricamento la riga deve restare com'è, nel tipo che si ricava dal contenuto. Inoltre, quando il segno iniziale viene cancellato, la riga deve tornare in corpo e non conservare un tipo di citazione, monospazio o voce numerata che la nota salverebbe e ripristinerebbe.
