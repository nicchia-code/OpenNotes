---
column: done
technical: false
refs:
  - requirements/rules#note-content-save
  - note-content-save/Waiting
drift: null
proposal: null
agent: false
created: 2026-10-12T11:21:17.876Z
finished: 2026-10-12T14:42:35.421Z
---
# Fix code to match the Model: Tags in notes accept letters of any alphabet, not only Latin ones

Un tag di una nota è fatto di lettere latine (quelle accentate incluse), cifre, «_» e «-». Oggi il riconoscimento dei tag accetta anche lettere di altri alfabeti: una parola scritta in cirillico, greco o con ideogrammi diventa un tag e compare nell'elenco e nel filtro. Quando il lavoro è finito, il salvataggio riconosce come tag solo i caratteri latini, nel testo e nelle celle delle tabelle, mentre le parole in altri alfabeti restano testo normale.
