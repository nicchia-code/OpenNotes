---
status: resolved
resolution: fix-code
refs:
  - note-content-save.NOTE_CONTENT_SAVED
proposal: null
task: ojsj17eo
origin: null
critical: false
option: 1
note: null
resolvedBy: 32w3ze0y
created: 2026-10-12T18:21:06.806Z
---
# A waiting content save is dropped when another note is edited within 400 ms

## What happens

Le modifiche al contenuto di una nota vengono scritte solo dopo 400 ms senza altri cambiamenti. Se una modifica di una nota è ancora in attesa e l'utente modifica un'altra nota, la modifica in attesa della prima viene sostituita da quella dell'altra. La prima nota non viene scritta né nel database né nel suo file: la lista mostra il testo appena scritto, ma al successivo aggiornamento torna la versione precedente.

## What should happen

Il Model e il Requirement dicono che le modifiche vengono salvate dopo 400 ms senza ulteriori modifiche, con un unico timer condiviso da tutte le note. Una modifica di una nota non deve andare perduta perché nel frattempo ne è stata modificata un'altra.

## Fix options

### Scrivere subito la modifica in attesa quando cambia nota

Quando arriva una modifica a un'altra nota, la modifica in attesa della precedente viene scritta subito, poi parte l'attesa per la nuova. Resta un solo timer e una sola modifica in attesa. Costo: una scrittura in più quando si passa rapidamente da una nota all'altra.

### Tenere un'attesa per ogni nota

Ogni nota conserva la propria modifica in attesa, e il timer condiviso scrive tutte quelle scadute. Nessuna modifica si perde anche con più note in pochi istanti. Costo: più stato nel gestore delle note e più scritture alla scadenza dell'attesa.

## Where in the code

lib/core/state/notes_provider.dart (updateNoteContent, flushPendingContent); lib/ui/editor/notion_document_editor.dart (didUpdateWidget cancels the editor wait without delivering it)
