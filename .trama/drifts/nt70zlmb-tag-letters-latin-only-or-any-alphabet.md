---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#note-content-save
proposal: null
task: 0gskn31j
origin: s01d7fus
critical: false
option: 1
note: null
resolvedBy: 3tg049lq
created: 2026-10-12T13:52:34.105Z
---
# Tag letters: Latin only or any alphabet

## What happens

Oggi il salvataggio riconosce come tag anche le parole scritte in cirillico, in greco o con ideogrammi: dopo un «#» diventano tag, compaiono nell'elenco e nel filtro e vengono evidenziati nel testo e nelle celle delle tabelle. Anche il completamento dei tag mentre si scrive accetta lettere di qualunque alfabeto.

## What should happen

Il Model dice che un tag è fatto di lettere latine (accentate incluse), cifre, «_» e «-», e che il salvataggio riconosce come tag solo i caratteri latini: le parole in altri alfabeti restano testo normale. La regola di salvataggio nei requisiti dice invece «lettere e cifre di qualunque alfabeto». Le due regole si contraddicono e non possono essere seguite entrambe, quindi non ho modificato il comportamento.

## Fix options

### Solo lettere latine, come nel Model

Salvataggio, evidenziazione e completamento riconoscono come tag solo lettere latine (accentate incluse), cifre, «_» e «-». Cirillico, greco e ideogrammi restano testo normale e non compaiono nell'elenco né nel filtro. Va allineata la regola dei requisiti. Costo: i tag scritti in altri alfabeti smettono di essere tag alla prossima scrittura della nota.

### Qualunque alfabeto, come nei requisiti

Il salvataggio riconosce come tag lettere e cifre di qualunque alfabeto, come fa oggi il codice. Tag in cirillico, greco o con ideogrammi compaiono nell'elenco e nel filtro. Va riscritta la definizione di tag nel Model. Costo: il Model e i requisiti restano in disaccordo fino alla modifica.

## Where in the code

Estrazione dei tag dal contenuto della nota (modello della nota), evidenziazione dei tag nell'editor di testo ricco, completamento dei tag nell'editor a blocchi
