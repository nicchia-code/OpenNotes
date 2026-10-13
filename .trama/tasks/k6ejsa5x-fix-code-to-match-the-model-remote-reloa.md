---
column: done
technical: false
refs:
  - note-editor/Open/sync-run.CLOUD_NOTE_APPLIED
  - note-editor/Open
drift: t9jho5wg
proposal: null
agent: false
created: 2026-10-12T17:41:18.211Z
finished: 2026-10-12T17:44:58.436Z
---
# Fix code to match the Model: Remote reload forgets the active part

## What happens

Quando arriva una versione remota della nota e l'editor la carica, il documento viene ricostruito e l'editor dimentica quale parte era attiva. Da quel momento i comandi della barra (grassetto, stile, checklist, tabella, foto) si applicano all'ultima sezione del documento, anche se l'ultima parte con il focus era un'altra.

## What should happen

Il Modello dice che la parte attiva è quella che ha il focus, altrimenti l'ultima che lo ha avuto. Dopo un aggiornamento remoto nessuna riga ha il focus, quindi la parte attiva dovrebbe restare quella che lo aveva avuto per ultima, non diventare l'ultima del documento.

## Chosen option

**Tenere la parte attiva per posizione**

Dopo il ricaricamento la parte attiva resta quella che lo era prima, riconosciuta dalla sua posizione nel documento. Se la posizione non esiste più nel documento ricevuto, si usa la seconda parte, come all'apertura. Costo: il codice deve ricordare la posizione prima di ricostruire il documento; il caso di un documento remoto con struttura diversa va gestito esplicitamente.

## Where in the code

lib/ui/editor/notion_document_editor.dart: didUpdateWidget (ramo di aggiornamento remoto, dove la parte attiva viene azzerata) e _currentActiveBlock (ricade sempre sull'ultima parte del documento).
