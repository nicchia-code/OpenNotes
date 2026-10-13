---
status: resolved
resolution: fix-code
refs:
  - text-line/In document/user.TOGGLE_CHECKLIST
  - requirements/rules#text-line
proposal: null
task: dbl0hlj8
origin: null
critical: false
option: 1
note: null
resolvedBy: xnzq15fv
created: 2026-10-12T08:27:54.154Z
---
# Checklist button changes all selected lines, not only the cursor line

## What happens

Con più righe selezionate, il pulsante checklist mette il cerchio vuoto su tutte le righe selezionate, se il cursore non è già su una checklist. Se invece il cursore è su una checklist, cambia solo la sua riga. Il risultato dipende quindi da dove si trova il cursore, non solo da quale riga è toccata.

## What should happen

Il Model dice che il pulsante agisce sulla riga del cursore, se la riga è una checklist la alterna, altrimenti le mette davanti il cerchio vuoto togliendo gli altri simboli. Il requisito dice lo stesso: alterna il cerchio sulla riga del cursore, altrimenti lo mette sulla riga del cursore. Il lavoro su più righe selezionate spetta al menu Aa.

## Fix options

### Agire sempre solo sulla riga del cursore

Il pulsante lavora sulla riga del cursore in entrambi i casi, come dice il requisito, e le altre righe selezionate restano invariate. Costo: per trasformare più righe in checklist bisogna usare il menu Aa oppure ripetere il pulsante riga per riga.

### Agire su tutte le righe selezionate in entrambi i casi

Il pulsante lavora su tutte le righe selezionate anche quando il cursore è su una checklist, così il comportamento è uguale in ogni caso. Costo: il requisito va cambiato, e una selezione mista può ritrovarsi con righe da fare e righe fatte alternate insieme.

## Where in the code

lib/ui/editor/rich_text_editing_controller.dart (toggleChecklistAtCursor, ramo senza checklist)
