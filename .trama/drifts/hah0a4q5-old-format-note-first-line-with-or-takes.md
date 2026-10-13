---
status: resolved
resolution: fix-code
refs:
  - text-line/Title
proposal: null
task: fyzqoyzc
origin: null
critical: false
option: 1
note: null
resolvedBy: ytpmwbt8
created: 2026-10-12T08:50:17.125Z
---
# Old-format note: first line with ## or ### takes Heading 2 or 3 instead of Title

## What happens

In una nota in formato precedente, se la prima riga significativa comincia con «## » o «### », la riga diventa Intestazione o Sottointestazione e non Titolo. Solo il prefisso «# » la fa diventare Titolo. Le prime righe con elenco o casella, invece, ricevono il Titolo.

## What should happen

Al caricamento, la prima riga significativa di una nota in formato precedente riceve lo stile Titolo, senza distinguere il prefisso. Il requisito sui prefissi «## » e «### » (Intestazione e Sottointestazione) riguarda la scrittura dopo una modifica, non il caricamento: il conflitto va deciso.

## Fix options

### Titolo anche con «## » o «### » come prima riga

La prima riga significativa di una nota in formato precedente diventa sempre Titolo, qualunque prefisso abbia, e il prefisso viene tolto. Le note che oggi mostrano un'Intestazione sulla prima riga cambiano stile al caricamento. Il testo resta uguale. Costo: piccolo cambio, solo nel caricamento.

### Mantenere Intestazione e Sottointestazione e precisare il Modello

Al caricamento solo «# » rende Titolo la prima riga; «## » e «### » restano Intestazione e Sottointestazione. Il Modello va completato su questo punto. Nessun cambio al codice. Le note già aperte non cambiano.

## Where in the code

lib/ui/editor/notion_document_editor.dart, ramo di ripiego di _parseContentToBlocks (righe con «## » e «### »), confronto con isFirstContentLine.
