---
column: done
technical: false
refs:
  - note-browser
  - note-browser/Browsing
  - requirements/data#note-browser
  - requirements/rules#note-browser
drift: null
proposal: null
agent: false
created: 2026-10-12T14:33:30.036Z
finished: 2026-10-12T16:28:34.087Z
---
# Fix code to match the Model: Tag list and tag filter ignore hashtags in note text

L'elenco dei tag e il filtro per tag leggono solo i tag salvati in ogni nota. Il Model dice invece che i tag di una nota sono quelli salvati uniti a quelli scritti nel suo testo come «#parola». Una nota creata con un testo iniziale non salva i #tag del testo: le note di benvenuto, create quando non c'è nessuna nota, hanno «#note», «#opennotes», «#todo» e «#produttività» e oggi non compaiono sotto questi tag. Quando è fatto, ogni tag scritto nel testo di una nota fuori dal cestino compare nell'elenco dei tag con il conteggio giusto e il filtro trova la nota, anche se la nota non è mai stata riscritta dall'editor.
