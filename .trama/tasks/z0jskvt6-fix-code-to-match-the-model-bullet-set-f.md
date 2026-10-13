---
column: done
technical: false
refs:
  - text-line/Bulleted item
drift: 8tmp5yhq
proposal: null
agent: false
created: 2026-10-12T08:09:28.401Z
finished: 2026-10-12T08:11:06.269Z
---
# Fix code to match the Model: Bullet set from the text style menu ignores the indent level

## What happens

Scegliendo «Elenco» dal menu Aa su una riga già rientrata, per esempio dopo un Tab, la riga riceve sempre il punto pieno, anche al secondo o al terzo livello. Un Invio successivo sulla stessa voce crea invece il simbolo del suo livello, cerchio vuoto o quadratino. Così la lista mostra simboli diversi per lo stesso livello.

## What should happen

Il Model dice che il simbolo di una voce puntata dipende dal livello di rientro: punto pieno, cerchio vuoto, quadratino, poi si ricomincia. I Requirements invece dicono che la scelta «Elenco» del menu Aa e del menu rapido mette davanti il prefisso «• », e che il simbolo di elenco segue il livello. Le due regole dei Requirements sono in conflitto per le righe rientrate, e il Model non dice quale vince dal menu.

## Chosen option

**Simbolo per livello anche dal menu**

Il menu Aa e il menu rapido mettono il simbolo che il livello della riga richiede, come fanno già Invio e Tab. La lista resta coerente in tutti i livelli. Costo: il Requirement sul prefisso «• » va riscritto per le righe rientrate, e la scelta dello stile deve leggere il rientro della riga.

## Where in the code

lib/ui/editor/notion_document_editor.dart, setBlockType; lib/ui/editor/rich_text_editing_controller.dart, applyLinePrefix
