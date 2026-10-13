---
column: done
technical: false
refs:
  - note-editor/Open/sync-run.CLOUD_NOTE_APPLIED
  - requirements/rules#note-editor
drift: ytz0a6hu
proposal: null
agent: false
created: 2026-10-12T15:18:03.660Z
finished: 2026-10-12T15:19:33.604Z
---
# Fix code to match the Model: Remote version reloads while a table cell has the cursor

## What happens

Quando arriva una versione remota della nota diversa da quella appena consegnata, l'editor la carica anche se il cursore è dentro una cella di tabella. Il controllo sul focus guarda solo le sezioni di testo: la tabella viene ricostruita e la cella perde il cursore mentre si sta scrivendo.

## What should happen

Il Modello dice che la versione remota viene caricata solo se **nessuna riga di testo** ha il focus. Il Requisito dice invece che **nessuna riga** deve avere il focus, e una riga di tabella ha il focus quando si scrive in una cella. Le due formulazioni non coincidono, quindi il comportamento va deciso.

## Chosen option

**Protect table cells too**

Una cella con il cursore conta come riga con il focus: la versione remota viene scartata, come per il testo, e la nota resta com'è finché non arriva una modifica successiva. Costo: una modifica remota può restare nascosta mentre si scrive in tabella. Il Modello va aggiornato in «nessuna riga, anche di tabella, ha il focus».

## Where in the code

lib/ui/editor/notion_document_editor.dart: _hasActiveFocus (guarda solo i focusNode delle sezioni di testo) e didUpdateWidget; le celle sono in InteractiveTableBlock
