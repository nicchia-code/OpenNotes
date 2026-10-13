---
column: done
technical: false
refs:
  - note-browser/Browsing
  - requirements/rules#note-browser
drift: null
proposal: null
agent: false
created: 2026-10-12T15:25:50.251Z
finished: 2026-10-12T16:32:57.740Z
---
# Fix code to match the Requirements: Tag filter misses stored tags with accented capitals

Quando si seleziona un tag, la lista delle note deve includere ogni nota che ha quel tag, anche se il tag salvato contiene lettere maiuscole accentate o di altri alfabeti (per esempio un tag arrivato dal cloud con la maiuscola). Il confronto deve avvenire sui tag convertiti in minuscolo, come fa già l'elenco dei tag, così che un tag mostrato nella barra laterale porti sempre alle note che lo contengono.
