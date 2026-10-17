---
column: done
technical: false
refs:
  - note-editor/Idle/sync-run.CLOUD_NOTE_APPLIED
  - requirements/rules#note-editor
drift: 74s806l4
proposal: null
agent: false
created: 2026-10-17T13:11:54.277Z
finished: 2026-10-17T13:44:21.875Z
---
# Fix code to match the Model: Remote version waits while a table cell has the cursor

## What happens

Con il cursore dentro una cella di tabella, una versione remota diversa da quella consegnata dall'editor non viene caricata. L'editor la ignora finché la cella ha il focus, e non la riprende quando il cursore esce dalla cella: la modifica fatta sull'altro dispositivo non compare nella nota aperta, finché non arriva un'altra versione o la nota non viene riaperta.

## What should happen

Il Modello dice che la versione remota si carica se è diversa dall'ultima consegnata e non c'è una modifica in attesa, anche se una riga di testo ha il focus. Il Requisito dice lo stesso, e aggiunge che il cursore resta nella stessa riga e posizione se esistono ancora. Né il Modello né il Requisito fanno eccezione per le celle di tabella.

## Chosen option

**Load the remote version and keep the cursor in its cell**

Il controllo sulle celle viene tolto, come quello sul testo. Dopo il caricamento il cursore torna nella stessa cella, alla stessa posizione, se esiste ancora. Costo: il testo digitato in quella cella può essere sostituito dalla versione remota, e il cursore nelle tabelle va ricostruito dopo ogni caricamento.

## Where in the code

lib/ui/editor/notion_document_editor.dart: didUpdateWidget, nella condizione che salta il caricamento compare _hasCellFocus; le celle sono in InteractiveTableBlock nello stesso file
