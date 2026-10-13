---
status: resolved
resolution: fix-code
refs:
  - note-editor/Open/user.TAP_CHECKBOX
  - requirements/rules#note-editor
proposal: null
task: tpnwscoa
origin: null
critical: false
option: 1
note: null
resolvedBy: xnzq15fv
created: 2026-10-12T08:27:58.783Z
---
# Checklist toggles when the first letters of an item are tapped

## What happens

Tocare il testo di una voce di checklist vicino all'inizio, cioè sulle prime lettere dopo il cerchio, cambia la spunta della voce. Chi tocca il testo solo per spostare il cursore vede la voce spuntata o tolta.

## What should happen

Il Model dice che la spunta cambia solo se il tocco cade sul cerchio della voce; il tocco sul testo deve soltanto posizionare il cursore. Anche i requisiti di salvataggio immediato parlano del tocco sul cerchio, non del testo.

## Fix options

### Toggle only when the tap is on the circle

La spunta cambia solo se il tocco cade sul cerchio, cioè prima o dopo il simbolo, senza coprire le lettere. Segue il Model alla lettera e non cambia il resto della riga. Costa che il bersaglio sul telefono è piccolo, quindi il tocco va più preciso.

### Separate tap area over the circle

Il cerchio diventa un'area di tocco separata dal campo di testo: il tocco su quell'area cambia la spunta, mentre il tocco sul testo sposta soltanto il cursore. Il bersaglio è più comodo da toccare, ma serve misurare la posizione del cerchio sulla riga e gestire il tocco a parte, quindi più codice da mantenere.

## Where in the code

lib/ui/editor/notion_document_editor.dart (onTap del campo di testo); lib/ui/editor/rich_text_editing_controller.dart (toggleChecklistAtOffset, soglia di offset prefisso + 1)
