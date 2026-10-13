---
column: done
technical: false
refs:
  - text-line/Title
drift: gn67rtks
proposal: null
agent: false
created: 2026-10-12T08:51:57.679Z
finished: 2026-10-12T08:54:11.767Z
---
# Fix code to match the Model: Block-format heading after an empty text line that follows a table is Heading 1, not Title

## What happens

In una nota in formato a blocchi, se tra due tabelle c'è un blocco di testo vuoto, la sezione di testo che segue la seconda tabella e comincia con «# » riceve lo stile Intestazione invece che Titolo. Le sezioni successive restano con la numerazione sbagliata.

## What should happen

Il Modello dice che la prima riga di una sezione di testo che comincia con «# » riceve lo stile Titolo. La sezione è il testo tra una tabella e la successiva, o l'inizio della nota: la riga dopo la seconda tabella deve quindi essere Titolo.

## Chosen option

**Riavviare il conteggio delle righe a ogni tabella**

Quando una sezione di testo si chiude, anche se è vuota, il conteggio delle righe riparte da zero. La riga «# » che segue la tabella diventa Titolo come nel Modello. Costo: piccolo cambio nel caricamento di note con tabelle e blocchi vuoti.

## Where in the code

lib/ui/editor/notion_document_editor.dart, ramo JSON di _parseContentToBlocks: flushText non riporta a zero currentLineIdx quando il testo della sezione è vuoto.
