---
status: resolved
resolution: proposal
refs:
  - editor-suggestions/Block menu/user.PICK_BLOCK_MENU_ITEM
proposal: null
task: null
origin: null
critical: false
option: null
note: null
resolvedBy: r3ka8qvl
created: 2026-10-18T20:13:44.845Z
---
# Slash removal also takes underscores and hyphens, the Requirement says letters and digits

## What happens

Scegliendo una voce del menu rapido, il «/» e il resto della parola che lo segue vengono tolti anche quando la parola contiene «_» o «-»: con «/lista-spesa» la riga perde «lista-spesa» per intero, e «/a_b» perde anche «_b». Il comportamento segue il riconoscimento dei tag, ma il Requisito non lo dice.

## What should happen

Il Requisito dice di togliere il «/» seguito da lettere e cifre di qualunque alfabeto e dagli spazi successivi, e nello stesso Requisito il tag è «lettere e cifre, «_» o «-»». La rimozione del comando non dice se «_» e «-» contano, quindi il Requisito e il codice non coincidono.

## Fix options

### Aggiungere «_» e «-» al Requisito

Il Requisito del menu rapido dice di togliere il «/» seguito da lettere e cifre di qualunque alfabeto, «_» e «-», come per i tag, e così il comportamento attuale diventa quello scritto. Costo: la parola con un trattino o un trattino basso sparisce per intero dalla riga, cosa che l'utente deve sapere.

### Togliere solo lettere e cifre

La rimozione del comando si ferma al primo «_» o «-», così la parte restante resta nella riga. Il Requisito resta com'è. Costo: «/lista-spesa» lascia «-spesa» nella riga, e la regola diverge dal riconoscimento dei tag, come già rilevato nel Drift 9nij8tfz.

## Where in the code

lib/ui/editor/notion_document_editor.dart, _removeSlashCommand (regex built from Note.tagNameChar, called by _transformBlock and the Tabella entry in _buildSlashMenu)
