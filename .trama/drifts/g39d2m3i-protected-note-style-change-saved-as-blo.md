---
status: resolved
resolution: fix-code
refs:
  - note-editor/Protected/user.SET_TEXT_STYLE
proposal: null
task: egomoubw
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:29:51.130Z
---
# Protected note: style change saved as block type

## What happens

Con la nota protetta e mai mostrata in questa sessione, lo stile scelto dal menu «Aa» diventa il tipo dell'intera sezione di testo, e viene salvato così. Al caricamento successivo lo stile tocca solo la prima riga della sezione, non la riga attiva.

## What should happen

Il Modello dice che lo stile cambia nella parte attiva del documento nascosto e viene salvato subito. La Requirement dice che ogni sezione di testo si salva come paragrafo, con gli stili di riga: un tipo di sezione diverso non deve comparire.

## Fix options

### Scrivere lo stile sulla riga attiva anche da nascosto

Il comando applica lo stile alla riga del cursore, come nella nota aperta, e lo salva come stile di riga. Il tipo della sezione resta paragrafo. Costo: serve ricavare la riga attiva senza l'editor visibile.

### Costruire l'editor anche per la nota nascosta

Il documento nascosto usa gli stessi controlli di testo della nota aperta, così il comando si comporta come sul testo visibile. Costo: più memoria e più lavoro anche quando la nota non è mostrata.

### Ignorare lo stile finché la nota non è aperta

Da nascosto il menu «Aa» non cambia nulla e non salva. Costo: l'utente deve aprire la nota prima di cambiare lo stile, e il comando sparisce senza avviso.

## Where in the code

lib/ui/editor/notion_document_editor.dart: setBlockType, ramo senza controller (assegna il tipo alla sezione); NoteBlock.toJson scrive il tipo così com'è.
