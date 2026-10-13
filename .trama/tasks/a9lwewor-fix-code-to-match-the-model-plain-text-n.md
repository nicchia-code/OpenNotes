---
column: done
technical: false
refs:
  - requirements/rules#export
  - export-markdown-share/Share sheet open
drift: 3jai3eb6
proposal: null
agent: false
created: 2026-10-12T07:38:53.673Z
finished: 2026-10-12T07:40:46.628Z
---
# Fix code to match the Model: Plain-text notes keep trailing blank lines when shared as Markdown

## What happens

Quando la nota è in testo semplice, il testo condiviso (e quello esportato) conserva gli spazi e le righe vuote finali del contenuto. Per le note a blocchi, invece, il risultato termina senza righe vuote.

## What should happen

La conversione in Markdown deve restituire un risultato privo di spazi e righe vuote finali, per qualsiasi nota: il testo condiviso deve terminare con l'ultimo contenuto utile, senza righe vuote in coda.

## Chosen option

**Ripulire anche il testo semplice**

Il testo semplice viene privato degli spazi e delle righe vuote finali, come già avviene per le note a blocchi. Il testo condiviso e il file esportato risultano sempre puliti. Costo: una riga di codice e un piccolo cambiamento per le note in testo semplice che oggi hanno righe vuote in coda.

## Where in the code

lib/core/models/note_model.dart, metodo toMarkdown (ramo testo semplice, senza rifinitura finale)
