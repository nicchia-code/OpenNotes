---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#note-content-save
proposal: null
task: xmiou4eh
origin: s01d7fus
critical: false
option: 1
note: null
resolvedBy: aq0a6puk
created: 2026-10-12T14:24:45.303Z
---
# Tag in altri alfabeti: Model e Requirement in conflitto

## What happens

Oggi una parola in cirillico, greco o con ideogrammi preceduta da «#» viene riconosciuta come tag nel testo e nelle celle delle tabelle, compare nell'elenco dei tag e nel filtro. Il Model dice che un tag è fatto solo di lettere latine (accentate incluse), cifre, «_» e «-», e che le altre parole restano testo normale.

## What should happen

Il Requirement di salvataggio delle note dice invece che un tag è «#nome» con lettere e cifre di qualunque alfabeto. Non si può rispettare sia il Model sia il Requirement: seguendo il Model il codice contraddice il Requirement, e seguendo il Requirement il codice contraddice il Model. Serve decidere quale dei due vale.

## Fix options

### Il Model vince: tag solo latini

Il riconoscimento dei tag accetta solo lettere latine (accentate incluse), cifre, «_» e «-», nel testo e nelle tabelle. Le parole in altri alfabeti tornano testo normale e spariscono da elenco e filtro. Il Requirement di salvataggio va aggiornato dal developer: il lavoro di codice è piccolo, ma le note già salvate con tag non latini vanno ricalcolate al prossimo salvataggio.

### Il Requirement vince: tag di qualunque alfabeto

Il riconoscimento accetta lettere di qualunque alfabeto, come oggi, e il Model va aggiornato. Non cambia il codice, ma il Model descrive un comportamento diverso dal codice e il Task viene chiuso senza modifiche.

## Where in the code

Il riconoscimento dei tag sta nel modello della nota (estrazione dal testo), nell'editor markdown (evidenziazione e completamento) e nel controller dell'editor a blocchi.
