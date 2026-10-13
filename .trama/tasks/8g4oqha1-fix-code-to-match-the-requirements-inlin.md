---
column: done
technical: false
refs:
  - export-markdown-share/Share sheet open
  - requirements/rules#export
drift: null
proposal: null
agent: false
created: 2026-10-13T06:33:28.223Z
finished: 2026-10-13T07:59:36.155Z
---
# Fix code to match the Requirements: Inline bold, italic and strikethrough split by other styles

Quando una nota viene convertita in Markdown per la condivisione o per l'esportazione, un tratto in grassetto, corsivo o barrato resta un solo blocco di marcatori, anche se un altro stile (per esempio il sottolineato, che non viene esportato) cade dentro lo stesso tratto. Il risultato non deve mostrare marcatori vicini come «**ciao ****mondo**» né spazi dentro i marcatori. Il grassetto e il corsivo insieme restano «***x***».
