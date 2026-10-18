---
status: resolved
resolution: fix-code
refs:
  - editor-suggestions/Block menu/user.PICK_BLOCK_MENU_ITEM
proposal: null
task: jen7tm5q
origin: null
critical: false
option: 1
note: null
resolvedBy: fxtjtht9
created: 2026-10-18T17:35:04.989Z
---
# Slash command removal stops at combining marks of other alphabets

## What happens

Scegliendo una voce del menu rapido, la rimozione del «/» e delle lettere che lo seguono si ferma al primo segno combinante, per esempio una vocale hindi o thai. Con «/किताब» nella riga restano «िताब». Il test esistente usa solo lettere precomposte («/caffè»), quindi non lo copre.

## What should happen

Il Requisito (rules/editor-text, menu rapido) dice di togliere il «/» seguito da lettere e cifre di qualunque alfabeto, e gli spazi successivi. Il riconoscimento dei tag usa già anche i segni combinanti (Note.tagNameChar, Task psjdhq26): la rimozione del comando deve usare lo stesso insieme di caratteri.

## Fix options

### Togliere anche i segni combinanti

La rimozione usa lo stesso insieme di caratteri dei tag (lettere, segni combinanti, cifre, «_» e «-»), così la parola di qualsiasi alfabeto sparisce per intero. Il test con «caffè» resta valido e va esteso a un caso con segni combinanti. Costo: nessuno di rilievo.

### Limitare il Requisito a lettere e cifre base

Il Requisito dice di togliere solo lettere e cifre base, e la rimozione resta com'è. Costo: nelle lingue con segni combinanti il comando lascia testo nella riga, e la regola diverge dal riconoscimento dei tag.

## Where in the code

lib/ui/editor/notion_document_editor.dart, _removeSlashCommand (regex ^/[\p{L}\p{N}]*\s*), chiamato dalla voce del menu rapido in _transformBlock e Tabella in _buildSlashMenu
