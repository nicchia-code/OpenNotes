---
column: done
technical: false
refs:
  - note-editor/Open/user.TAP_CHECKBOX
  - requirements/rules#note-editor
drift: wkoe92qh
proposal: null
agent: false
created: 2026-10-12T08:30:16.657Z
finished: 2026-10-12T08:32:06.769Z
---
# Fix code to match the Model: Checklist toggles when the first letters of an item are tapped

## What happens

Tocare il testo di una voce di checklist vicino all'inizio, cioè sulle prime lettere dopo il cerchio, cambia la spunta della voce. Chi tocca il testo solo per spostare il cursore vede la voce spuntata o tolta.

## What should happen

Il Model dice che la spunta cambia solo se il tocco cade sul cerchio della voce; il tocco sul testo deve soltanto posizionare il cursore. Anche i requisiti di salvataggio immediato parlano del tocco sul cerchio, non del testo.

## Chosen option

**Toggle only when the tap is on the circle**

La spunta cambia solo se il tocco cade sul cerchio, cioè prima o dopo il simbolo, senza coprire le lettere. Segue il Model alla lettera e non cambia il resto della riga. Costa che il bersaglio sul telefono è piccolo, quindi il tocco va più preciso.

## Where in the code

lib/ui/editor/notion_document_editor.dart (onTap del campo di testo); lib/ui/editor/rich_text_editing_controller.dart (toggleChecklistAtOffset, soglia di offset prefisso + 1)
