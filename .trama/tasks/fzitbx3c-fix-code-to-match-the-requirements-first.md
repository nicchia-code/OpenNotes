---
column: done
technical: true
refs:
  - requirements/rules#text-line
drift: xbpgtvvo
proposal: null
agent: false
created: 2026-10-12T14:20:57.168Z
finished: 2026-10-12T14:23:06.545Z
---
# Fix code to match the Requirements: First line style lost when a selection starting at a line start is replaced

## What happens

Se si sostituisce o si cancella una selezione che comincia all'inizio di una riga con stile, come un'intestazione, e finisce su una riga in corpo, la riga che resta diventa corpo: lo stile della prima riga va perso. Accade anche quando l'ultima riga toccata non ha alcuno stile.

## What should happen

Secondo la regola sugli stili dopo una modifica, se prima del punto modificato non c'era testo la riga che resta prende lo stile dell'ultima riga toccata; se anche questa è in corpo, la riga tiene il proprio stile. Quindi l'intestazione deve restare.

## Chosen option

**Mantenere lo stile della prima riga**

Quando l'ultima riga toccata è in corpo, la riga che resta conserva lo stile della prima riga, come dice il requisito. Il modello non cambia. Costo: una correzione piccola nel punto in cui si sceglie lo stile dopo una modifica, più un caso di prova per una selezione che parte da inizio riga.

## Where in the code

lib/ui/editor/rich_text_editing_controller.dart: _reconcileLineStyles, the line that chooses the surviving style when the change does not keep the start line
