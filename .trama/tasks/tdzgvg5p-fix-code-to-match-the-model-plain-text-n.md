---
column: done
technical: false
refs:
  - requirements/rules#note-content-save
  - note-content-save/Waiting
drift: null
proposal: null
agent: false
created: 2026-10-12T11:21:18.072Z
finished: 2026-10-12T16:27:29.304Z
---
# Fix code to match the Model: Plain-text note that looks like a JSON list gets the default title

Una nota di testo semplice la cui prima riga inizia con «[» e che, letta come lista, risulta valida (per esempio «[]» o «[1]») riceve il titolo «Nuova nota», anche se la prima riga contiene testo. Il titolo deve essere la prima riga di testo, come per ogni nota di testo semplice, e l'anteprima deve partire dal testo che segue. Quando il lavoro è finito, una nota di testo semplice ottiene sempre il titolo dalla sua prima riga, qualunque sia il contenuto di quella riga.
