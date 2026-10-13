---
column: done
technical: false
refs:
  - export-markdown-file/Choosing destination
  - requirements/rules#export
drift: r0awdofi
proposal: null
agent: false
created: 2026-10-12T07:38:53.701Z
finished: 2026-10-12T07:50:55.170Z
---
# Fix code to match the Model: Plain-text notes exported without cleanup and list conversion

## What happens

Una nota in testo semplice viene esportata quasi com'è: se finisce con spazi o righe vuote, il file le conserva. Inoltre, una nota in testo semplice la cui prima lettera è `[` viene trattata come documento a blocchi illeggibile e restituita senza alcuna conversione, anche se non è affatto un documento a blocchi: i simboli ○, ● e • restano come sono.

## What should happen

Il risultato esportato non deve avere spazi né righe vuote finali, e ogni nota in testo semplice deve avere la stessa conversione dei simboli di lista, qualunque sia il suo primo carattere. Solo un documento a blocchi non leggibile resta com'è.

## Chosen option

**Applicare la pulizia e la conversione anche al testo semplice**

La nota in testo semplice passa dalla stessa rifinitura finale, e il riconoscimento del documento a blocchi si fa provando a leggerlo, non guardando il primo carattere. Il file esportato cambia solo per le note con spazi finali o simboli di lista; le note già a blocchi non cambiano. Costo: una modifica nella stessa funzione e un controllo in più per le note che iniziano con `[`.

## Where in the code

lib/core/models/note_model.dart, Note.toMarkdown: il ramo del testo semplice, che non applica la rifinitura finale, e il controllo iniziale sul carattere `[`
