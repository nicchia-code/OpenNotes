---
status: resolved
resolution: fix-code
refs:
  - editor-suggestions/Block menu
proposal: null
task: icygep61
origin: mye3y7ge
critical: false
option: 1
note: null
resolvedBy: psazi867
created: 2026-10-12T16:26:38.610Z
---
# Block menu opened from the toolbar missing from the Model

## What happens

Il pulsante del menu blocchi sulla barra sopra la tastiera del telefono apre già il menu rapido sotto la sezione corrente, con le sette voci. Il Modello di Block menu però non ha nessuna transizione che lo apra dalla barra: il menu compare solo quando la sezione comincia con una barra digitata a mano. Il comportamento in codice non è quindi descritto dal Modello, e la Proposal m16unv7j, indicata come risoluzione del Drift 63qylj4f, non ha aggiunto la transizione.

## What should happen

Il Requisito di editor-suggestions vuole che sul telefono il menu compaia toccando il suo pulsante sulla barra. Il Modello non ha questa apertura, quindi il comportamento non si può far combaciare con il Modello senza decidere come si apre il menu, e il pulsante Aa apre già un altro elenco.

## Fix options

### Completare il Modello con l'apertura dalla barra

Si aggiunge al Modello di Block menu una transizione: il pulsante della barra apre il menu rapido sotto la sezione corrente, con le sette voci. Il codice resta com'è. Costo: una transizione nuova da mantenere e il rischio di confonderla con il pulsante Aa.

### Togliere il pulsante dalla barra

Il menu si apre solo digitando una barra all'inizio della sezione, come nel Modello. Il pulsante del menu blocchi sparisce dalla barra sul telefono. Costo: il Requisito sull'apertura dalla barra non è più seguito, e il Requisito va cambiato.

## Where in the code

lib/ui/mobile/mobile_keyboard_accessory_bar.dart; lib/ui/editor/notion_document_editor.dart
