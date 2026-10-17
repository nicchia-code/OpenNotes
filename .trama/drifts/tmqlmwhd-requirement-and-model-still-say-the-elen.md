---
status: resolved
resolution: proposal
refs:
  - text-line/In document/user.SET_TEXT_STYLE
  - requirements/rules#text-line
proposal: null
task: null
origin: null
previous: 8tmp5yhq
critical: false
option: null
note: null
resolvedBy: 1mjjves7
created: 2026-10-17T09:49:29.850Z
---
# Requirement and Model still say the Elenco menu sets a fixed «• » symbol

## What happens

Scegliendo «Elenco» dal menu Aa o dal menu rapido su una riga rientrata, il codice mette il simbolo del livello di rientro (•, ◦, ▪), non sempre «• ». Così il menu e Invio/Tab producono lo stesso simbolo per lo stesso livello. Il Requirement dice ancora che la scelta mette davanti «• » e il Model dice «mette davanti il punto», quindi resta un conflitto scritto anche se il codice è già allineato alla decisione presa con 8tmp5yhq.

## What should happen

Il Model dice che il simbolo di una voce puntata dipende dal livello di rientro (sezione Bulleted item), e la decisione di 8tmp5yhq è che anche il menu Aa e il menu rapido seguano il livello. Il Requirement «Stile da Aa» dice invece che «Elenco» mette davanti il prefisso «• », e lo stesso Requirement dice poi che il simbolo segue il livello: la regola va riscritta in modo coerente.

## Fix options

### Rewrite the Requirement: the menu uses the level symbol

Il menu Aa e il menu rapido mettono il simbolo del livello di rientro, come già fa il codice. Il Requirement «Stile da Aa» va riscritto per le righe rientrate, e il Model dice «mette davanti il simbolo del livello» invece di «il punto». Costo: una modifica ai Requirements e al testo del Model, nessun cambio di codice.

### Keep the fixed symbol from the menu

Il menu mette sempre «• » anche sulle righe rientrate, come dice il Requirement attuale. Il simbolo per livello vale solo per Invio e Tab. Costo: un cambio nel codice di setBlockType e applyLinePrefix, e liste con simboli diversi per lo stesso livello, da spiegare nel Model.

## Where in the code

lib/ui/editor/notion_document_editor.dart, setBlockType (chiamata applyLinePrefix con bulletByIndent per BlockType.bullet); lib/ui/editor/rich_text_editing_controller.dart, applyLinePrefix (linePrefix con getBulletForIndent).
