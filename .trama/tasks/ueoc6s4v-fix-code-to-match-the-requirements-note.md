---
column: done
technical: false
refs:
  - note-content-save/Waiting
drift: null
proposal: null
agent: false
created: 2026-10-18T16:42:48.353Z
finished: 2026-10-18T16:46:21.275Z
---
# Fix code to match the Requirements: Note list keeps the discarded text after a failed save

Se una scrittura fallisce e la versione non scritta viene scartata perché un'altra nota ha già una versione in attesa, il Requisito dice che la nota torna all'ultima versione salvata. Nel codice, _writeContent (ramo catch) non riallinea _notes: l'elenco mostra ancora il testo scartato di quella nota (inserito da _showWaitingContent alla consegna) finché un salvataggio riuscito non chiama refreshNotes. Da correggere: nel ramo di scarto ricaricare la nota dal database (o ripristinare la versione salvata in _notes) e notificare gli ascoltatori. Riferimenti: lib/core/state/notes_provider.dart, _writeContent (righe 413–417) e _showWaitingContent (441–447).
