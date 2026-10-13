---
column: done
technical: true
refs:
  - requirements/rules#note-content-save
drift: nt70zlmb
proposal: null
agent: false
created: 2026-10-12T14:20:57.099Z
finished: 2026-10-12T14:23:35.891Z
---
# Fix code to match the Requirements: Tag letters: Latin only or any alphabet

## What happens

Oggi il salvataggio riconosce come tag anche le parole scritte in cirillico, in greco o con ideogrammi: dopo un «#» diventano tag, compaiono nell'elenco e nel filtro e vengono evidenziati nel testo e nelle celle delle tabelle. Anche il completamento dei tag mentre si scrive accetta lettere di qualunque alfabeto.

## What should happen

Il Model dice che un tag è fatto di lettere latine (accentate incluse), cifre, «_» e «-», e che il salvataggio riconosce come tag solo i caratteri latini: le parole in altri alfabeti restano testo normale. La regola di salvataggio nei requisiti dice invece «lettere e cifre di qualunque alfabeto». Le due regole si contraddicono e non possono essere seguite entrambe, quindi non ho modificato il comportamento.

## Chosen option

**Solo lettere latine, come nel Model**

Salvataggio, evidenziazione e completamento riconoscono come tag solo lettere latine (accentate incluse), cifre, «_» e «-». Cirillico, greco e ideogrammi restano testo normale e non compaiono nell'elenco né nel filtro. Va allineata la regola dei requisiti. Costo: i tag scritti in altri alfabeti smettono di essere tag alla prossima scrittura della nota.

## Where in the code

Estrazione dei tag dal contenuto della nota (modello della nota), evidenziazione dei tag nell'editor di testo ricco, completamento dei tag nell'editor a blocchi
