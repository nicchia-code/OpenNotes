---
column: done
technical: false
refs:
  - text-line/In document
  - requirements/rules#text-line
drift: null
proposal: null
agent: false
created: 2026-10-13T14:03:03.353Z
finished: 2026-10-13T14:04:30.259Z
---
# Fix code to match the Model: Text style menu keeps the second leading symbol of a line

Il menu Aa (e il menu rapido dei blocchi) toglie solo il primo simbolo iniziale di una riga. Il Model dice che lo stile scelto toglie qualunque simbolo iniziale, e i Requirements dicono che prima di applicare lo stile si tolgono tutti i prefissi esistenti (solo se seguiti da uno spazio). Quando una riga ha due simboli di fila, per esempio una citazione con un numero dentro («> 1. testo») o un elenco con una citazione dentro («- > testo»), scegliere Corpo, Titolo, Intestazione o un altro stile lascia il secondo simbolo nel testo: «> 1. testo» diventa «1. testo» in stile corpo, e alla modifica successiva la riga torna voce numerata. Quando lo stile scelto è applicato, la riga deve avere come unico simbolo iniziale quello dello stile scelto, senza altri simboli rimasti nel testo.
