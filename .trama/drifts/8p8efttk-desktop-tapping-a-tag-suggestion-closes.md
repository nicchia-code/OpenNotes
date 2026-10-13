---
status: resolved
resolution: fix-code
refs:
  - editor-suggestions/Tag suggestions
  - requirements/rules#editor-suggestions
proposal: null
task: p9xl0pc2
origin: null
critical: false
option: 1
note: null
resolvedBy: fiomlg7l
created: 2026-10-13T05:22:11.187Z
---
# Desktop: tapping a tag suggestion closes the menu without inserting the tag

## What happens

Sul computer, con il mouse, cliccando un suggerimento di tag (o il pulsante «Crea») il campo di testo perde il focus prima che la scelta venga registrata. Il menu si chiude e il tag non viene inserito: il testo parziale «#…» resta com'è. Dalla lettura del codice risulta che il menu dei tag non è nella stessa zona di tocco del campo di testo, a differenza del menu rapido dei blocchi, che la ha; non è stato provato su un dispositivo desktop. Sul telefono con il tocco il comportamento non cambia.

## What should happen

Scegliere un suggerimento deve sostituire il testo dal «#» al cursore con «#nome » e mettere il cursore dopo lo spazio, come descrive il Model per il passaggio Tag suggestions → Hidden (PICK_TAG_SUGGESTION) e come richiede il Requisito. Il clic con il mouse deve fare la stessa cosa del tocco e della scelta da tastiera.

## Fix options

### Keep the tag menu inside the text-field tap area

Il menu dei tag viene avvolto nella stessa zona di tocco già usata dal menu rapido dei blocchi, così il clic non toglie il focus al testo e la scelta avviene come nel Model. Il cambiamento è di una riga; va verificato anche il pulsante «Crea» sul desktop. Costo: nessuno sul telefono, da ripetere su ogni nuovo menu che compare sotto il testo.

### Choose the tag when the press starts

La scelta avviene alla pressione del suggerimento, non al rilascio, e quindi prima che il campo perda il focus. Non serve toccare la zona di tocco, ma il comportamento diventa diverso dagli altri pulsanti del menu, che agiscono al rilascio. Costo: l'ordine tra pressione e perdita del focus va verificato sul desktop, e il comportamento resta legato a quell'ordine.

## Where in the code

lib/ui/editor/notion_document_editor.dart: _buildFloatingTagMenu (menu dei tag, nello Stack della build), confrontato con il menu rapido dei blocchi _buildSlashMenu, racchiuso in TextFieldTapRegion.
