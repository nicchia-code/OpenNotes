---
column: done
technical: false
refs:
  - text-line/In document
  - requirements/rules#text-line
drift: q2felqo7
proposal: null
agent: false
created: 2026-10-12T07:38:53.817Z
finished: 2026-10-12T07:52:46.501Z
---
# Fix code to match the Model: Text style menu leaves the symbol on indented lines

## What happens

Su una voce rientrata, per esempio un elenco puntato a cui è stato dato un Tab, scegliere Corpo, Titolo, Intestazione o un altro stile dal menu Aa lascia il simbolo originale davanti al testo: scegliere Corpo non toglie il pallino, e un nuovo elenco si aggiunge davanti al simbolo già presente, con due simboli uno dopo l'altro. Lo stesso succede al pulsante checklist sulle righe rientrate.

## What should happen

Il Model dice che lo stile scelto toglie qualunque simbolo iniziale e poi applica il nuovo stile. I Requirements dicono che, prima di applicare lo stile, si tolgono i prefissi esistenti. Il rientro non deve impedire di togliere il simbolo: lo stile scelto deve restare l'unico simbolo della riga.

## Chosen option

**Togliere il simbolo dopo il rientro**

Il menu Aa e il pulsante checklist riconoscono il simbolo anche dopo gli spazi di rientro, lo tolgono e poi rimettono il nuovo simbolo al posto giusto. Il rientro resta com'è, così le voci di corpo rimangono rientrate come dopo un Tab. Costo: si cambia il punto che toglie i prefissi, da provare con righe a più livelli e con ogni stile del menu.

## Where in the code

lib/ui/editor/rich_text_editing_controller.dart, removeLinePrefixes e applyLinePrefix; lib/ui/editor/notion_document_editor.dart, setBlockType
