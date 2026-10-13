---
status: resolved
resolution: fix-code
refs:
  - text-line/Bulleted item
  - requirements/rules#text-line
proposal: null
task: tq0fltrn
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:30:46.617Z
---
# Enter at the start of a list item duplicates the symbol

## What happens

Premendo Invio con il cursore prima del testo di una voce puntata, numerata o di checklist, il simbolo compare due volte: la riga sopra resta vuota senza simbolo e la voce con il testo diventa per esempio «• • testo» oppure «○ ○ testo». Lo stesso accade con il cursore all'inizio di una voce numerata.

## What should happen

Il Model dice che Invio su una voce con testo crea sotto una nuova voce con lo stesso rientro. Anche con il cursore all'inizio della voce, il testo deve restare in una sola voce con un solo simbolo, e la voce nuova deve nascere sotto. I Requirements dicono lo stesso: nuova voce con il simbolo del livello, o con il numero successivo.

## Fix options

### Dividere la voce come nel mezzo del testo

Con il cursore all'inizio, la voce resta vuota con il suo simbolo sopra, e il testo passa in una nuova voce sotto con un solo simbolo. È lo stesso comportamento che c'è già quando il cursore è in mezzo al testo, quindi non serve una regola nuova. Costo: la voce di sopra resta vuota, e la stessa regola vale per le voci numerate e di checklist.

### Inserire una voce vuota sopra

Con il cursore all'inizio, Invio crea una voce vuota sopra e il testo resta sulla sua riga con il cursore, senza essere spostato. Il Model va riscritto per questo caso, perché la divisione in mezzo al testo resta diversa. Costo: la regola cambia tra inizio e centro della voce, e va descritta nel Model.

## Where in the code

lib/ui/editor/rich_text_editing_controller.dart, handleEnterKey (rami di checklist, voci puntate e voci numerate)
