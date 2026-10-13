---
status: resolved
resolution: fix-code
refs:
  - text-line/Heading
  - requirements/rules#text-line
proposal: null
task: xboph9vh
origin: null
critical: false
option: 1
note: null
resolvedBy: xnzq15fv
created: 2026-10-12T08:27:45.217Z
---
# Old-format note: a leading blank line takes the title style

## What happens

In una nota in formato precedente che comincia con una riga vuota, quella riga vuota diventa il titolo. La prima riga con testo resta un corpo normale, senza stile di titolo.

## What should happen

Il Model dice che il titolo di una nota in formato precedente è la prima riga significativa, cioè quella con testo, non vuota e non fatta solo di tag. Le righe vuote iniziali non devono prendere lo stile di titolo.

## Fix options

### Saltare le righe vuote nella scelta del titolo

La prima riga con testo, non fatta solo di tag, riceve lo stile di titolo, come dice il Model. Le righe vuote iniziali restano corpo. Costo: una regola di caricamento da cambiare, senza migrazione dei dati; le note già salvate in questo formato vengono lette in modo diverso alla prossima apertura.

### Accettare il titolo sulla riga vuota e correggere il Model

La riga vuota iniziale resta titolo e il Model viene corretto per dire che conta la prima riga, anche vuota. Costo: il titolo risulta vuoto e la prima riga con testo perde lo stile di titolo; il Model diventa meno chiaro sulla nota come titolo.

## Where in the code

lib/ui/editor/notion_document_editor.dart (caricamento in formato precedente, _parseContentToBlocks)
