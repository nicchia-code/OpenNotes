---
column: done
technical: false
refs:
  - note-editor/Protected/user.SET_TEXT_STYLE
drift: g39d2m3i
proposal: null
agent: false
created: 2026-10-12T07:38:53.776Z
finished: 2026-10-12T07:43:53.490Z
---
# Fix code to match the Model: Protected note: style change saved as block type

## What happens

Con la nota protetta e mai mostrata in questa sessione, lo stile scelto dal menu «Aa» diventa il tipo dell'intera sezione di testo, e viene salvato così. Al caricamento successivo lo stile tocca solo la prima riga della sezione, non la riga attiva.

## What should happen

Il Modello dice che lo stile cambia nella parte attiva del documento nascosto e viene salvato subito. La Requirement dice che ogni sezione di testo si salva come paragrafo, con gli stili di riga: un tipo di sezione diverso non deve comparire.

## Chosen option

**Scrivere lo stile sulla riga attiva anche da nascosto**

Il comando applica lo stile alla riga del cursore, come nella nota aperta, e lo salva come stile di riga. Il tipo della sezione resta paragrafo. Costo: serve ricavare la riga attiva senza l'editor visibile.

## Where in the code

lib/ui/editor/notion_document_editor.dart: setBlockType, ramo senza controller (assegna il tipo alla sezione); NoteBlock.toJson scrive il tipo così com'è.
