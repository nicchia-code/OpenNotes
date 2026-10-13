---
status: resolved
resolution: fix-code
refs:
  - editor-suggestions/Block menu
proposal: null
task: kmbhgb30
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:25:33.148Z
---
# Menu rapido dei blocchi non si apre dalla barra

## What happens

Il menu rapido dei blocchi si apre solo digitando «/» all'inizio della sezione. La barra degli strumenti sulla tastiera del telefono non lo apre: il pulsante **Aa** mostra un altro elenco di formati (Titolo, Intestazione, Sottointestazione, Corpo, Elenco Puntato, Elenco Numerato, Sottolineato) con voci diverse dal menu rapido.

## What should happen

Il Modello descrive il menu rapido dei blocchi come **aperto dalla barra**, con le voci Checklist, Intestazione, Sottointestazione, Elenco, Numerato, Citazione e Tabella. Nel Modello, però, lo stato si raggiunge solo digitando «/», e la barra non ha alcuna transizione.

## Fix options

### Aprire il menu rapido dalla barra

Un pulsante della barra apre il menu rapido sotto la sezione corrente, con le sette voci. Il Modello va completato con questa apertura dalla barra, che diventa una transizione. Costo: un pulsante in più sulla barra e una transizione nuova da disegnare e da mantenere.

### Correggere la descrizione del Modello

Il menu resta aperto solo digitando «/», come oggi nel codice. Si toglie dalla descrizione del Modello l'apertura dalla barra. Costo: sulla barra non c'è un modo rapido per le stesse voci; il menu **Aa** resta un elenco diverso e va spiegato a parte.

## Where in the code

lib/ui/editor/notion_document_editor.dart (apertura del menu in _handleTextChanged); lib/ui/mobile/mobile_keyboard_accessory_bar.dart (menu Aa).
