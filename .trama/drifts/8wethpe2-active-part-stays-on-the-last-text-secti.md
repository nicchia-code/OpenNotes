---
status: resolved
resolution: fix-code
refs:
  - note-editor/Open
proposal: null
task: 3kjow3go
origin: null
critical: false
option: 1
note: null
resolvedBy: p136jufl
created: 2026-10-12T08:07:17.277Z
---
# Active part stays on the last text section while the cursor is in a table

## What happens

Con il cursore dentro una cella di tabella, la parte attiva dell'editor resta l'ultima sezione di testo che ha avuto il focus. Quindi i comandi della barra (grassetto, corsivo, sottolineato, stile, checklist, tabella, foto) agiscono su quella sezione, non sulla tabella in cui si sta scrivendo. Tabella e foto vengono inserite dopo la sezione di testo, anche quando la tabella in cui si scrive sta più in basso. I comandi di formattazione e stile portano anche il cursore fuori dalla tabella, nella sezione di testo.

## What should happen

Il Modello dice che la parte attiva è quella che ha il focus, altrimenti l'ultima che lo ha avuto. Una tabella con il cursore in una delle sue celle ha il focus, quindi è lei la parte attiva: tabella e foto vanno inserite dopo di lei e i comandi non devono portare il cursore fuori dalla tabella.

## Fix options

### Considerare attiva la tabella in cui si scrive

Quando il cursore entra in una cella, la tabella diventa la parte attiva. Tabella, foto e disegno si inseriscono dopo di lei, e i comandi di testo non fanno nulla finché il cursore è nella tabella. Per formattare occorre prima toccare una sezione di testo. Costo: una regola in più sul focus delle celle, che oggi non tocca la parte attiva.

### Tenere attiva l'ultima sezione di testo

Il Modello cambia: la parte attiva resta l'ultima sezione di testo che ha avuto il focus, anche mentre il cursore è in una tabella. Tabella e foto si inseriscono dopo quella sezione, come oggi, e i comandi di formattazione riportano il cursore nella sezione di testo. Costo: la tabella in cui si scrive può trovarsi sopra il punto d'inserimento, e il Modello va riscritto.

## Where in the code

lib/ui/editor/notion_document_editor.dart: _currentActiveBlock e _activeBlock. Il focus di una sezione di testo aggiorna la parte attiva nel listener del suo focus node; le celle della tabella (InteractiveTableBlock) hanno nodi di focus propri e non lo aggiornano.
