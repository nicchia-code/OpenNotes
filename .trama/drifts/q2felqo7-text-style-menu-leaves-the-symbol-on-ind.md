---
status: resolved
resolution: fix-code
refs:
  - text-line/In document
  - requirements/rules#text-line
proposal: null
task: 7040vdf5
origin: null
critical: false
option: 1
note: null
resolvedBy: 3pikg137
created: 2026-10-12T07:30:46.743Z
---
# Text style menu leaves the symbol on indented lines

## What happens

Su una voce rientrata, per esempio un elenco puntato a cui è stato dato un Tab, scegliere Corpo, Titolo, Intestazione o un altro stile dal menu Aa lascia il simbolo originale davanti al testo: scegliere Corpo non toglie il pallino, e un nuovo elenco si aggiunge davanti al simbolo già presente, con due simboli uno dopo l'altro. Lo stesso succede al pulsante checklist sulle righe rientrate.

## What should happen

Il Model dice che lo stile scelto toglie qualunque simbolo iniziale e poi applica il nuovo stile. I Requirements dicono che, prima di applicare lo stile, si tolgono i prefissi esistenti. Il rientro non deve impedire di togliere il simbolo: lo stile scelto deve restare l'unico simbolo della riga.

## Fix options

### Togliere il simbolo dopo il rientro

Il menu Aa e il pulsante checklist riconoscono il simbolo anche dopo gli spazi di rientro, lo tolgono e poi rimettono il nuovo simbolo al posto giusto. Il rientro resta com'è, così le voci di corpo rimangono rientrate come dopo un Tab. Costo: si cambia il punto che toglie i prefissi, da provare con righe a più livelli e con ogni stile del menu.

### Togliere anche il rientro

Quando si sceglie uno stile dal menu, la riga torna senza rientro e senza simbolo, poi riceve il nuovo stile. Il Model resta valido così com'è e non serve scrivere il caso del rientro. Costo: il rientro voluto dall'utente si perde a ogni cambio di stile, cosa che oggi non succede e va detta nel Model.

## Where in the code

lib/ui/editor/rich_text_editing_controller.dart, removeLinePrefixes e applyLinePrefix; lib/ui/editor/notion_document_editor.dart, setBlockType
