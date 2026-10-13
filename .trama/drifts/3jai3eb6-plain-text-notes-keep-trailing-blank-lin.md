---
status: resolved
resolution: fix-code
refs:
  - requirements/rules#export
  - export-markdown-share/Share sheet open
proposal: null
task: a9lwewor
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:24:40.668Z
---
# Plain-text notes keep trailing blank lines when shared as Markdown

## What happens

Quando la nota è in testo semplice, il testo condiviso (e quello esportato) conserva gli spazi e le righe vuote finali del contenuto. Per le note a blocchi, invece, il risultato termina senza righe vuote.

## What should happen

La conversione in Markdown deve restituire un risultato privo di spazi e righe vuote finali, per qualsiasi nota: il testo condiviso deve terminare con l'ultimo contenuto utile, senza righe vuote in coda.

## Fix options

### Ripulire anche il testo semplice

Il testo semplice viene privato degli spazi e delle righe vuote finali, come già avviene per le note a blocchi. Il testo condiviso e il file esportato risultano sempre puliti. Costo: una riga di codice e un piccolo cambiamento per le note in testo semplice che oggi hanno righe vuote in coda.

### Documentare l'eccezione

Il codice resta com'è e la regola si limita alle note a blocchi. Nessun cambiamento nell'app, ma il testo condiviso di una nota in testo semplice può terminare con righe vuote, e la specifica va corretta per dirlo esplicitamente.

## Where in the code

lib/core/models/note_model.dart, metodo toMarkdown (ramo testo semplice, senza rifinitura finale)
