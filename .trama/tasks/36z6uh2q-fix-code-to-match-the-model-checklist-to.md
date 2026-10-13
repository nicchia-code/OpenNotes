---
column: done
technical: false
refs:
  - text-line/Unchecked
  - requirements/rules#text-line
drift: wectbghw
proposal: null
agent: false
created: 2026-10-12T07:38:53.807Z
finished: 2026-10-12T07:46:34.104Z
---
# Fix code to match the Model: Checklist toggle keeps the heading style

## What happens

Premendo il pulsante checklist sulla riga di un titolo o di un'intestazione, la riga diventa una voce da fare con il cerchio vuoto, ma resta grande e in grassetto come il titolo.

## What should happen

Il Model dice che il pulsante checklist toglie i simboli e mette davanti il cerchio vuoto, quindi la riga diventa una voce da fare, in stile corpo: lo stile di intestazione non vale più. I Requirements dicono che il pulsante mette davanti «○ » togliendo gli altri prefissi, senza parlare di stile.

## Chosen option

**Portare la riga in corpo**

Il pulsante checklist su una riga di titolo o intestazione riporta la riga in stile corpo nello stesso gesto in cui mette il cerchio, come già fa la scelta Checklist del menu Aa. Il comportamento è quello descritto dal Model e non servono altre decisioni. Costo: quella riga perde la dimensione del titolo, che è il risultato voluto dal Model.

## Where in the code

lib/ui/editor/rich_text_editing_controller.dart, toggleChecklistAtCursor
