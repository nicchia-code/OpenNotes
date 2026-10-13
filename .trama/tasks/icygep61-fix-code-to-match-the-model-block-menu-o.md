---
column: done
technical: false
refs:
  - editor-suggestions/Block menu
drift: 6sbfb2vu
proposal: null
agent: false
created: 2026-10-12T17:14:49.768Z
finished: 2026-10-12T17:25:56.265Z
---
# Fix code to match the Model: Block menu opened from the toolbar missing from the Model

## What happens

Il pulsante del menu blocchi sulla barra sopra la tastiera del telefono apre già il menu rapido sotto la sezione corrente, con le sette voci. Il Modello di Block menu però non ha nessuna transizione che lo apra dalla barra: il menu compare solo quando la sezione comincia con una barra digitata a mano. Il comportamento in codice non è quindi descritto dal Modello, e la Proposal m16unv7j, indicata come risoluzione del Drift 63qylj4f, non ha aggiunto la transizione.

## What should happen

Il Requisito di editor-suggestions vuole che sul telefono il menu compaia toccando il suo pulsante sulla barra. Il Modello non ha questa apertura, quindi il comportamento non si può far combaciare con il Modello senza decidere come si apre il menu, e il pulsante Aa apre già un altro elenco.

## Chosen option

**Completare il Modello con l'apertura dalla barra**

Si aggiunge al Modello di Block menu una transizione: il pulsante della barra apre il menu rapido sotto la sezione corrente, con le sette voci. Il codice resta com'è. Costo: una transizione nuova da mantenere e il rischio di confonderla con il pulsante Aa.

## Where in the code

lib/ui/mobile/mobile_keyboard_accessory_bar.dart; lib/ui/editor/notion_document_editor.dart
