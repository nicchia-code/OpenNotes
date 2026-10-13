---
column: done
technical: false
refs:
  - text-line/Monospace
  - requirements/rules#text-line
drift: null
proposal: null
agent: false
created: 2026-10-12T11:42:45.372Z
finished: 2026-10-12T14:07:22.706Z
---
# Fix code to match the Model: Checklist button on a monospace line leaves a double space after the circle

Su una riga in monospazio scritta con il menu Aa, quindi con il segno «``` » con lo spazio dopo gli apici, il pulsante checklist mette « ○ » davanti al testo che resta, e il risultato è «○  testo» con due spazi. Il segno del monospazio è «``` » con lo spazio, quindi lo spazio va tolto insieme agli apici e la riga deve diventare «○ testo». Il caso «```testo» senza spazio già funziona.
