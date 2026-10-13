---
column: done
technical: false
refs:
  - text-line/Heading
  - requirements/rules#text-line
drift: 56uiwkvb
proposal: null
agent: false
created: 2026-10-12T08:30:16.642Z
finished: 2026-10-12T08:32:14.255Z
---
# Fix code to match the Model: Old-format note: a leading blank line takes the title style

## What happens

In una nota in formato precedente che comincia con una riga vuota, quella riga vuota diventa il titolo. La prima riga con testo resta un corpo normale, senza stile di titolo.

## What should happen

Il Model dice che il titolo di una nota in formato precedente è la prima riga significativa, cioè quella con testo, non vuota e non fatta solo di tag. Le righe vuote iniziali non devono prendere lo stile di titolo.

## Chosen option

**Saltare le righe vuote nella scelta del titolo**

La prima riga con testo, non fatta solo di tag, riceve lo stile di titolo, come dice il Model. Le righe vuote iniziali restano corpo. Costo: una regola di caricamento da cambiare, senza migrazione dei dati; le note già salvate in questo formato vengono lette in modo diverso alla prossima apertura.

## Where in the code

lib/ui/editor/notion_document_editor.dart (caricamento in formato precedente, _parseContentToBlocks)
