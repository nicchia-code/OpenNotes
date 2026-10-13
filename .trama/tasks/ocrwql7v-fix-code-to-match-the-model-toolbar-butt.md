---
column: done
technical: false
refs:
  - editor-suggestions/Block menu
drift: re008pm1
proposal: null
agent: false
created: 2026-10-12T11:53:12.013Z
finished: 2026-10-12T11:55:03.989Z
---
# Fix code to match the Model: Toolbar button opens Block menu not in Model

## What happens

Il pulsante Aa sulla barra sopra la tastiera del telefono apre l'elenco dei formati e non il menu rapido dei blocchi. Il menu rapido compare solo quando la sezione comincia con una barra digitata a mano. Nessuna transizione del Model di Block menu apre il menu dalla barra.

## What should happen

Il Requisito di editor-suggestions dice che sul telefono il menu rapido compare toccando il suo pulsante sulla barra, con le sette voci Checklist, Intestazione, Sottointestazione, Elenco, Numerato, Citazione e Tabella. Il Model non ha una transizione per questa apertura, quindi il comportamento non si può seguire senza inventarlo. La Proposal m16unv7j, indicata come risoluzione del Drift 63qylj4f, non ha aggiunto questa transizione.

## Chosen option

**Completare il Modello con l'apertura dalla barra**

Si aggiunge al Model di Block menu una transizione: il pulsante della barra apre il menu rapido sotto la sezione corrente con le sette voci. Poi si implementa il pulsante. Costo: un pulsante in più e una transizione nuova da mantenere, con possibile sovrapposizione al pulsante Aa.

## Where in the code

lib/ui/mobile/mobile_keyboard_accessory_bar.dart; lib/ui/editor/notion_document_editor.dart
