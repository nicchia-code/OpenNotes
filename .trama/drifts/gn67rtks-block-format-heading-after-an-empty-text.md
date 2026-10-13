---
status: resolved
resolution: fix-code
refs:
  - text-line/Title
proposal: null
task: 5vrtm9kc
origin: null
critical: false
option: 1
note: null
resolvedBy: ytpmwbt8
created: 2026-10-12T08:50:17.436Z
---
# Block-format heading after an empty text line that follows a table is Heading 1, not Title

## What happens

In una nota in formato a blocchi, se tra due tabelle c'è un blocco di testo vuoto, la sezione di testo che segue la seconda tabella e comincia con «# » riceve lo stile Intestazione invece che Titolo. Le sezioni successive restano con la numerazione sbagliata.

## What should happen

Il Modello dice che la prima riga di una sezione di testo che comincia con «# » riceve lo stile Titolo. La sezione è il testo tra una tabella e la successiva, o l'inizio della nota: la riga dopo la seconda tabella deve quindi essere Titolo.

## Fix options

### Riavviare il conteggio delle righe a ogni tabella

Quando una sezione di testo si chiude, anche se è vuota, il conteggio delle righe riparte da zero. La riga «# » che segue la tabella diventa Titolo come nel Modello. Costo: piccolo cambio nel caricamento di note con tabelle e blocchi vuoti.

### Tenere l'Intestazione e precisare il Modello

Si accetta che il titolo sia solo la prima riga della nota o di una sezione che segue una riga normale, e il Modello va precisato. Nessun cambio al codice. Le note già aperte non cambiano.

## Where in the code

lib/ui/editor/notion_document_editor.dart, ramo JSON di _parseContentToBlocks: flushText non riporta a zero currentLineIdx quando il testo della sezione è vuoto.
