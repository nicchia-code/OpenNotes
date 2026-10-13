---
column: done
technical: false
refs:
  - text-line/Title
drift: hah0a4q5
proposal: null
agent: false
created: 2026-10-12T08:51:57.672Z
finished: 2026-10-12T08:53:04.791Z
---
# Fix code to match the Model: Old-format note: first line with ## or ### takes Heading 2 or 3 instead of Title

## What happens

In una nota in formato precedente, se la prima riga significativa comincia con «## » o «### », la riga diventa Intestazione o Sottointestazione e non Titolo. Solo il prefisso «# » la fa diventare Titolo. Le prime righe con elenco o casella, invece, ricevono il Titolo.

## What should happen

Al caricamento, la prima riga significativa di una nota in formato precedente riceve lo stile Titolo, senza distinguere il prefisso. Il requisito sui prefissi «## » e «### » (Intestazione e Sottointestazione) riguarda la scrittura dopo una modifica, non il caricamento: il conflitto va deciso.

## Chosen option

**Titolo anche con «## » o «### » come prima riga**

La prima riga significativa di una nota in formato precedente diventa sempre Titolo, qualunque prefisso abbia, e il prefisso viene tolto. Le note che oggi mostrano un'Intestazione sulla prima riga cambiano stile al caricamento. Il testo resta uguale. Costo: piccolo cambio, solo nel caricamento.

## Where in the code

lib/ui/editor/notion_document_editor.dart, ramo di ripiego di _parseContentToBlocks (righe con «## » e «### »), confronto con isFirstContentLine.
