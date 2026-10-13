---
status: resolved
resolution: fix-code
refs:
  - note-editor/Open/sync-run.CLOUD_NOTE_APPLIED
  - requirements/rules#note-editor
proposal: null
task: hbdqpd0v
origin: null
critical: false
option: 1
note: null
resolvedBy: ke2oiwmu
created: 2026-10-12T15:14:22.963Z
---
# Remote version reloads while a table cell has the cursor

## What happens

Quando arriva una versione remota della nota diversa da quella appena consegnata, l'editor la carica anche se il cursore è dentro una cella di tabella. Il controllo sul focus guarda solo le sezioni di testo: la tabella viene ricostruita e la cella perde il cursore mentre si sta scrivendo.

## What should happen

Il Modello dice che la versione remota viene caricata solo se **nessuna riga di testo** ha il focus. Il Requisito dice invece che **nessuna riga** deve avere il focus, e una riga di tabella ha il focus quando si scrive in una cella. Le due formulazioni non coincidono, quindi il comportamento va deciso.

## Fix options

### Protect table cells too

Una cella con il cursore conta come riga con il focus: la versione remota viene scartata, come per il testo, e la nota resta com'è finché non arriva una modifica successiva. Costo: una modifica remota può restare nascosta mentre si scrive in tabella. Il Modello va aggiornato in «nessuna riga, anche di tabella, ha il focus».

### Keep text lines only and narrow the Requirement

Il focus protegge solo il testo, come già scritto nel Modello, e il Requisito va corretto in «nessuna riga di testo». Nessun cambiamento nel codice. Costo: se una versione remota arriva mentre si scrive in una cella, la tabella viene ricostruita e ciò che si stava digitando in quella cella può essere sostituito dal contenuto remoto.

## Where in the code

lib/ui/editor/notion_document_editor.dart: _hasActiveFocus (guarda solo i focusNode delle sezioni di testo) e didUpdateWidget; le celle sono in InteractiveTableBlock
