---
status: resolved
resolution: fix-code
refs:
  - text-line/Unchecked
  - requirements/rules#text-line
proposal: null
task: 36z6uh2q
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:30:46.499Z
---
# Checklist toggle keeps the heading style

## What happens

Premendo il pulsante checklist sulla riga di un titolo o di un'intestazione, la riga diventa una voce da fare con il cerchio vuoto, ma resta grande e in grassetto come il titolo.

## What should happen

Il Model dice che il pulsante checklist toglie i simboli e mette davanti il cerchio vuoto, quindi la riga diventa una voce da fare, in stile corpo: lo stile di intestazione non vale più. I Requirements dicono che il pulsante mette davanti «○ » togliendo gli altri prefissi, senza parlare di stile.

## Fix options

### Portare la riga in corpo

Il pulsante checklist su una riga di titolo o intestazione riporta la riga in stile corpo nello stesso gesto in cui mette il cerchio, come già fa la scelta Checklist del menu Aa. Il comportamento è quello descritto dal Model e non servono altre decisioni. Costo: quella riga perde la dimensione del titolo, che è il risultato voluto dal Model.

### Tenere lo stile del titolo

La voce resta in stile intestazione con il cerchio davanti, e il Model dichiara che il pulsante checklist non cambia lo stile della riga. Costo: una voce di checklist grande, da descrivere nel Model, e una differenza con il menu Aa che oggi porta la riga in corpo.

## Where in the code

lib/ui/editor/rich_text_editing_controller.dart, toggleChecklistAtCursor
