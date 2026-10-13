---
column: done
technical: true
refs:
  - requirements/rules#note-content-save
drift: t796620d
proposal: null
agent: false
created: 2026-10-12T14:39:15.704Z
finished: 2026-10-12T14:41:50.598Z
---
# Fix code to match the Requirements: Tag in altri alfabeti: Model e Requirement in conflitto

## What happens

Oggi una parola in cirillico, greco o con ideogrammi preceduta da «#» viene riconosciuta come tag nel testo e nelle celle delle tabelle, compare nell'elenco dei tag e nel filtro. Il Model dice che un tag è fatto solo di lettere latine (accentate incluse), cifre, «_» e «-», e che le altre parole restano testo normale.

## What should happen

Il Requirement di salvataggio delle note dice invece che un tag è «#nome» con lettere e cifre di qualunque alfabeto. Non si può rispettare sia il Model sia il Requirement: seguendo il Model il codice contraddice il Requirement, e seguendo il Requirement il codice contraddice il Model. Serve decidere quale dei due vale.

## Chosen option

**Il Model vince: tag solo latini**

Il riconoscimento dei tag accetta solo lettere latine (accentate incluse), cifre, «_» e «-», nel testo e nelle tabelle. Le parole in altri alfabeti tornano testo normale e spariscono da elenco e filtro. Il Requirement di salvataggio va aggiornato dal developer: il lavoro di codice è piccolo, ma le note già salvate con tag non latini vanno ricalcolate al prossimo salvataggio.

## Where in the code

Il riconoscimento dei tag sta nel modello della nota (estrazione dal testo), nell'editor markdown (evidenziazione e completamento) e nel controller dell'editor a blocchi.
