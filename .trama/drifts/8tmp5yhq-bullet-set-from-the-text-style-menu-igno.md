---
status: resolved
resolution: fix-code
refs:
  - text-line/Bulleted item
proposal: null
task: z0jskvt6
origin: null
critical: false
option: 1
note: null
resolvedBy: p136jufl
created: 2026-10-12T08:04:12.918Z
---
# Bullet set from the text style menu ignores the indent level

## What happens

Scegliendo «Elenco» dal menu Aa su una riga già rientrata, per esempio dopo un Tab, la riga riceve sempre il punto pieno, anche al secondo o al terzo livello. Un Invio successivo sulla stessa voce crea invece il simbolo del suo livello, cerchio vuoto o quadratino. Così la lista mostra simboli diversi per lo stesso livello.

## What should happen

Il Model dice che il simbolo di una voce puntata dipende dal livello di rientro: punto pieno, cerchio vuoto, quadratino, poi si ricomincia. I Requirements invece dicono che la scelta «Elenco» del menu Aa e del menu rapido mette davanti il prefisso «• », e che il simbolo di elenco segue il livello. Le due regole dei Requirements sono in conflitto per le righe rientrate, e il Model non dice quale vince dal menu.

## Fix options

### Simbolo per livello anche dal menu

Il menu Aa e il menu rapido mettono il simbolo che il livello della riga richiede, come fanno già Invio e Tab. La lista resta coerente in tutti i livelli. Costo: il Requirement sul prefisso «• » va riscritto per le righe rientrate, e la scelta dello stile deve leggere il rientro della riga.

### Sempre il punto pieno dal menu

Il menu mette sempre il punto pieno, anche sulle righe rientrate, e il simbolo per livello vale solo per le voci create con Invio o Tab. Il Model va scritto in modo che la scelta dal menu non dipenda dal rientro. Costo: liste con simboli diversi per lo stesso livello, da spiegare nel Model e nei Requirements.

## Where in the code

lib/ui/editor/notion_document_editor.dart, setBlockType; lib/ui/editor/rich_text_editing_controller.dart, applyLinePrefix
